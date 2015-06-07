# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013, 2014, 2015 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""ubuntu-weather-app tests and emulators - top level package."""
from ubuntuuitoolkit import MainView, UbuntuUIToolkitCustomProxyObjectBase


class UbuntuWeatherAppException(Exception):
    """Exception raised when there's an error in the Weather App."""


def click_object(func):
    """Wrapper which clicks the returned object"""
    def func_wrapper(self, *args, **kwargs):
        return self.pointing_device.click_object(func(self, *args, **kwargs))

    return func_wrapper


class UbuntuWeatherApp(object):
    """Autopilot helper object for the Weather application."""

    def __init__(self, app_proxy):
        self.app = app_proxy
        self.main_view = self.app.wait_select_single(MainView)

    def get_add_location_page(self):
        return self.main_view.wait_select_single(
            AddLocationPage, objectName="addLocationPage")


class Page(UbuntuUIToolkitCustomProxyObjectBase):
    """Autopilot helper for Pages."""
    def __init__(self, *args):
        super(Page, self).__init__(*args)


class AddLocationPage(Page):
    """Autopilot helper for AddLocationPage."""
    def __init__(self, *args):
        super(AddLocationPage, self).__init__(*args)


class MainView(MainView):
    """Autopilot custom proxy object for the MainView."""
    retry_delay = 0.2

    def __init__(self, *args):
        super(MainView, self).__init__(*args)
        self.visible.wait_for(True)