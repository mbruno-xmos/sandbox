/*
 * clapper.xc
 *
 *  Created on: Aug 8, 2017
 *      Author: mbruno
 */

#include <platform.h>
#include <xs1.h>
#include <string.h>
#include <stdint.h>
#include <stdio.h>
#include <xclib.h>
#include <xscope.h>

#include "mic_array.h"
#include "mic_array_board_support.h"
#include "debug_print.h"

#include "i2c.h"
#include "i2s.h"

/*
 * Application parameters
 */
#define LED_CIRCLE_COUNT (MIC_BOARD_SUPPORT_LED_COUNT-1)
#define LED_ADVANCE_DELAY 10000000
#define LED_BRIGHTNESS_DELTA 4
#define DOUBLE_CLICK_TIME_WINDOW 50000000
#define MIN_TIME_BETWEEN_CLAPS 12500000
#define CLAP_MAGNITUDE 512

/*
 * Parameters copied from AN00218
 */
#define MASTER_TO_PDM_CLOCK_DIVIDER 4
#define DECIMATION_FACTOR   2   //Corresponds to a 48kHz output sample rate
#if ETHERNET
#define DECIMATOR_COUNT     2   //8 channels requires 2 decimators
#else
#define DECIMATOR_COUNT     1   //4 channels requires 1 decimator
#endif
#define FRAME_BUFFER_COUNT  2   //The minimum of 2 will suffice for this example

mabs_led_ports_t leds = MIC_BOARD_SUPPORT_LED_PORTS;
in port p_buttons =  MIC_BOARD_SUPPORT_BUTTON_PORTS;


#if ETHERNET

#define DAC_TILE tile[1]
#define MIC_TILE tile[0]
#define BUTTON_LED_TILE tile[0]
#define I2C_SCL_BITPOS 0
#define I2C_SDA_BITPOS 1

//Ports for the PDM microphones
out port p_pdm_clk              = PORT_PDM_CLK;
in buffered port:32 p_pdm_mics  = PORT_PDM_DATA;
in port p_mclk                  = PORT_MCLK_TILE0;
on MIC_TILE: clock pdmclk       = XS1_CLKBLK_1;

#elif SMART_MIC_4TILE

#define DAC_TILE tile[1]
#define MIC_TILE tile[2]
#define BUTTON_LED_TILE tile[3]
#define I2C_SCL_BITPOS 1
#define I2C_SDA_BITPOS 2

//Ports for the PDM microphones
out port p_pdm_clk              = PORT_PDM_CLK;
in buffered port:32 p_pdm_mics  = PORT_PDM_DATA /*PORT_PDM_DATA*/;
in port p_mclk                  = PORT_PDM_MCLK;
on MIC_TILE: clock pdmclk       = XS1_CLKBLK_1;

#else
#error "Target platform not supported"
#endif


static int led_advance(int led, int direction)
{
    if (direction > 0) {
        if (++led >= LED_CIRCLE_COUNT) {
            led = 0;
        }
    } else if (direction < 0) {
        if (led-- <= 0) {
            led = LED_CIRCLE_COUNT-1;
        }
    }

    return led;
}

static void led_race(client interface mabs_led_button_if lb, chanend clap_channel, uint32_t led_advance_delay)
{
    timer t;
    timer t2;
    uint32_t time_to_advance;
    uint32_t double_press_time;
    int i, led;
    int single_pressed;
    int direction = 1;

    led = 0;
    double_press_time = 0;
    single_pressed = 0;

    t :> time_to_advance;

    for (;;) {

        select {
        case t when timerafter(time_to_advance) :> void:

            for (i = 0; i < LED_CIRCLE_COUNT; i++) {
                lb.set_led_brightness(led, (i+1)*LED_BRIGHTNESS_DELTA);
                led = led_advance(led, direction);
            }

            led = led_advance(led, direction);

            time_to_advance += led_advance_delay;

            break;

        case single_pressed => t2 when timerafter(double_press_time) :> uint32_t curtime:

            single_pressed = 0;

//            printf("double press timer expire\n");

            break;

        case clap_channel :> int clap:

            if (!single_pressed) {
//                printf("single press\n");
                direction = -direction;
                single_pressed = 1;
                t2 :> double_press_time;
                double_press_time += DOUBLE_CLICK_TIME_WINDOW;
            } else {
//                printf("double press\n");
                if (direction != 0) {
                    direction = 0;
                } else {
                    direction = 1;
                }
                single_pressed = 0;
            }

            break;

        case lb.button_event():
            unsigned int button;
            mabs_button_state_t pressed;
            lb.get_button_event(button, pressed);
            if (pressed == BUTTON_PRESSED) {
                switch(button) {
                case 0:
                    if (!single_pressed) {
//                        printf("single press\n");
                        direction = -direction;
                        single_pressed = 1;
                        t2 :> double_press_time;
                        double_press_time += DOUBLE_CLICK_TIME_WINDOW;
                    } else {
//                        printf("double press\n");
                        if (direction != 0) {
                            direction = 0;
                        } else {
                            direction = 1;
                        }
                        single_pressed = 0;
                    }
                    break;
                }
            }
            break;
        }
    }
}

int detect_clap(int audio_sample)
{
    timer t;
    static uint32_t last_time;
    static int heard_clap;
    static unsigned avg_magnitude;
    uint32_t time;
    unsigned value;
    unsigned magnitude;

    value = audio_sample >> 20;
    magnitude = (value * value) >> 8;

    avg_magnitude = (avg_magnitude - avg_magnitude/512 + magnitude);

    xscope_int(MAGNITUDE, magnitude);
    xscope_int(AVG_MAGNITUDE, avg_magnitude/512);

    if (heard_clap) {

        if (avg_magnitude <= 512*CLAP_MAGNITUDE/8) {

            t :> time;

            if (time - last_time >= MIN_TIME_BETWEEN_CLAPS/2) {
                heard_clap = 0;
//                printf("clap gone (%u) @ %u\n", avg_magnitude/512, time);
            }
        }
    } else if (avg_magnitude >= 512*CLAP_MAGNITUDE) {

        t :> time;

        if (time - last_time >= MIN_TIME_BETWEEN_CLAPS) {
            last_time = time;
            heard_clap = 1;
//            printf("clap (%u) @ %u\n", avg_magnitude/512, time);
            return 1;
        }
    }

    return 0;
}


void audio_get(streaming chanend c_ds_output[DECIMATOR_COUNT], chanend clap_channel)
{
    int fir_decimator_data[8][THIRD_STAGE_COEFS_PER_STAGE*DECIMATION_FACTOR];
    mic_array_frame_time_domain audio[FRAME_BUFFER_COUNT];
    unsigned buffer;

    unsafe {

        mic_array_decimator_conf_common_t dcc = {0, 1, 0, 0, DECIMATION_FACTOR,
               g_third_stage_div_2_fir, 0, FIR_COMPENSATOR_DIV_2,
               DECIMATOR_NO_FRAME_OVERLAP, FRAME_BUFFER_COUNT};
        mic_array_decimator_config_t dc[2] = {
          {&dcc, fir_decimator_data[0], {INT_MAX, INT_MAX, INT_MAX, INT_MAX}, 4},
          {&dcc, fir_decimator_data[4], {INT_MAX, INT_MAX, INT_MAX, INT_MAX}, 4}
        };

        memset(fir_decimator_data, 0, 8*THIRD_STAGE_COEFS_PER_STAGE*DECIMATION_FACTOR*sizeof(int));

        mic_array_decimator_configure(c_ds_output, DECIMATOR_COUNT, dc);

        mic_array_init_time_domain_frame(c_ds_output, DECIMATOR_COUNT, buffer, audio, dc);

        for (;;) {
            int output = 0;
            int i;
            mic_array_frame_time_domain *current = mic_array_get_next_time_domain_frame(c_ds_output, DECIMATOR_COUNT, buffer, audio, dc);

#if ETHERNET
            for (i = 0; i < 7; i++) {
                output += current->data[i][0] >> 3;
            }
#else
            for (i = 0; i < 4; i++) {
                output += current->data[i][0] >> 2;
            }
#endif

            output = ((int64_t) output * (int64_t) (1<<16)) >> 16;

            if (detect_clap(output)) {
                clap_channel <: 1;
            }
        }
    }
}

int main()
{
    interface mabs_led_button_if lb[1];

    streaming chan c_pdm_to_hires[DECIMATOR_COUNT];
    streaming chan c_ds_output[DECIMATOR_COUNT];
    chan clap_channel;

    par {

        on MIC_TILE: {
            configure_clock_src_divide(pdmclk, p_mclk, MASTER_TO_PDM_CLOCK_DIVIDER);
            configure_port_clock_output(p_pdm_clk, pdmclk);
            configure_in_port(p_pdm_mics, pdmclk);
            start_clock(pdmclk);

            par {
    #if ETHERNET
                mic_array_pdm_rx(p_pdm_mics, c_pdm_to_hires[0], c_pdm_to_hires[1]);
                mic_array_decimate_to_pcm_4ch(c_pdm_to_hires[0], c_ds_output[0], MIC_ARRAY_NO_INTERNAL_CHANS);
                mic_array_decimate_to_pcm_4ch(c_pdm_to_hires[1], c_ds_output[1], MIC_ARRAY_NO_INTERNAL_CHANS);
    #else
                mic_array_pdm_rx(p_pdm_mics, c_pdm_to_hires[0], NULL);
                mic_array_decimate_to_pcm_4ch(c_pdm_to_hires[0], c_ds_output[0], MIC_ARRAY_NO_INTERNAL_CHANS);
    #endif
                audio_get(c_ds_output, clap_channel);
            }
        }

        on BUTTON_LED_TILE: {
            par {
                mabs_button_and_led_server(lb, 1, leds, p_buttons);
                led_race(lb[0], clap_channel, LED_ADVANCE_DELAY);
            }
        }

    }

    return 0;
}
