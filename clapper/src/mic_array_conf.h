// Copyright (c) 2015-2016, XMOS Ltd, All rights reserved
#ifndef MIC_ARRAY_CONF_H_
#define MIC_ARRAY_CONF_H_

#define MIC_ARRAY_MAX_FRAME_SIZE_LOG2 0
#if ETHERNET
#define MIC_ARRAY_NUM_MICS 8
#else
#define MIC_ARRAY_NUM_MICS 4
#endif
#define MIC_ARRAY_FIXED_GAIN 4


#endif /* MIC_ARRAY_CONF_H_ */
