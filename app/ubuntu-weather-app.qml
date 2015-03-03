/*
 * Copyright (C) 2015 Canonical Ltd
 *
 * This file is part of Ubuntu Weather App
 *
 * Ubuntu Weather App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * Ubuntu Weather App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.3
import Qt.labs.settings 1.0
import Ubuntu.Components 1.1
import "components"
import "data" as Data
import "data/WeatherApi.js" as WeatherApi
import "data/key.js" as Key
import "ui"

MainView {
    id: weatherApp

    objectName: "weather"

    applicationName: "com.ubuntu.weather"

    automaticOrientation: false

    width: units.gu(40)
    height: units.gu(70)

    backgroundColor: "#F5F5F5"

    useDeprecatedToolbar: false
    anchorToKeyboard: true

    /*
      List of locations and their data, accessible through index
    */
    property var locationsList: []    

    /*
      Index of Location before a refresh, to go back after
    */
    property int indexAtRefresh: -1

    /*
      (re)load the pages on completion
    */
    Component.onCompleted: refreshData();

    /*
      Handle response data from data backend. Checks if a location
      was updated and has to be stored again.
    */
    function responseDataHandler(messageObject) {
         if(!messageObject.error) {
             if(messageObject.action === "updateData") {
                 messageObject.result.forEach(function(loc) {
                     // replace location data in cache with refreshed values
                     if(loc["save"] === true) {
                         storage.updateLocation(loc.db.id, loc);
                     }
                 });
                 //print(JSON.stringify(messageObject.result));
                 fillPages(messageObject.result);
             }
         } else {
             console.log(messageObject.error.msg+" / "+messageObject.error.request.url)
             // TODO error handling
         }
     }

    /* Fill the location pages with their data. */
    function fillPages(locations) {
        locationsList = []
        locationsList = locations;
    }

    /*
      Refresh data, either directly from storage or by checking against
      API instead.
    */
    function refreshData(from_storage, force_refresh) {
        if(from_storage === true && force_refresh !== true) {
            storage.getLocations(fillPages);
        } else {
            storage.getLocations(function(locations) {
                WeatherApi.sendRequest({
                    action: "updateData",
                    params: {
                        locations: locations,
                        force: force_refresh,
                        service: settings.service,
                        api_key: Key.twcKey,
                        interval: settings.refreshInterval
                    }
                }, responseDataHandler)
            });
        }
    }

    Settings {
        id: settings
        category: "weatherSettings"
        /*
          Index of the current locationList of locations and their data, accessible through index
        */
        property int current: 0

        property int refreshInterval: 1800
        property string precipUnits
        property string service
        property string tempScale
        property string units
        property string windUnits

        property bool migrated: false

        Component.onCompleted: {
            if (units === "") {  // No settings so load defaults
                console.debug("No settings, using defaults")
                var metric = Qt.locale().measurementSystem === Locale.MetricSystem

                precipUnits = metric ? "mm" : "in"
                service = "weatherchannel"
                tempScale = "°" + (metric ? "C" : "F")
                units = metric ? "metric" : "imperial"
                windUnits = metric ? "kmh" : "mph"
            }
        }
    }

    Data.Storage {
        id: storage

        // Add the location to the storage and refresh the locationList
        // Return true if a location is added
        function addLocation(location) {
            var exists = checkLocationExists(location)

            if(!exists) {
                if(location.dbId === undefined || location.dbId=== 0) {
                    storage.insertLocation({location: location});
                }

                refreshData(false, true)
            }

            return !exists;
        }

        // Return true if the location given is already in the locationsList
        function checkLocationExists(location) {
            var exists = false;

            for (var i=0; !exists && i < locationsList.length; i++) {
                var loc = locationsList[i].location;

                if (loc.services.geonames && (loc.services.geonames === location.services.geonames)) {
                    exists = true;
                }
            }

            return exists;
        }
    }

    PageStack {
        id: mainPageStack
        Component.onCompleted: mainPageStack.push(Qt.resolvedUrl("ui/HomePage.qml"))
    }
}
