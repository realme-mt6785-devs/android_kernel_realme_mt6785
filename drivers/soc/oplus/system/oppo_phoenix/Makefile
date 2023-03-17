# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2018-2020 Oplus. All rights reserved.
ifeq ($(CONFIG_OPLUS_FEATURE_PHOENIX),y)
ifneq ($(filter oppo6785_20682 oppo6769_19741 oppo6769_19747 oppo6785_19661 oppo6785_20741, $(OPPO_TARGET_DEVICE)),)
CFLAGS_KERNEL += -DPHX_PET_TIMEOUT_X2
CFLAGS_MODULE += -DPHX_PET_TIMEOUT_X2
endif

obj-$(CONFIG_OPLUS_FEATURE_PHOENIX) += op_bootprof.o
obj-$(CONFIG_OPLUS_FEATURE_PHOENIX) += phoenix_base.o
obj-$(CONFIG_OPLUS_FEATURE_PHOENIX) += phoenix_dump.o
obj-$(CONFIG_OPLUS_FEATURE_PHOENIX) += phoenix_watchdog.o
endif