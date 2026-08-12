obj-$(CONFIG_EXYNOS_DECON_LCD_EA8076)	+= ea8076_mipi_lcd.o ea8076_lcd_ctrl.o

obj-y += dsim_panel.o ../decon_board.o ../decon_notify.o ../decon_abd.o
obj-$(CONFIG_DISPLAY_USE_INFO) += dpui.o
obj-$(CONFIG_EXYNOS_DECON_MDNIE) += mdnie.o

obj-$(and $(CONFIG_EXYNOS_DECON_MDNIE),$(CONFIG_SEC_GPIO_DVS),$(subst undefined,y,$(origin CONFIG_SAMSUNG_PRODUCT_SHIP))) += dd_mdnie.o
obj-$(and $(CONFIG_SEC_GPIO_DVS),$(subst undefined,y,$(origin CONFIG_SAMSUNG_PRODUCT_SHIP))) += dd_lcd.o dd_backlight.o dd_dpu.o dd_param.o

obj-$(CONFIG_EXYNOS_DECON_LCD_EA8076_A50)	+= ea8076_a50_lcd_ctrl.o
obj-$(and $(CONFIG_EXYNOS_DECON_LCD_EA8076_A50),$(CONFIG_SUPPORT_POC_FLASH)) += ea8076_a50_poc.o
