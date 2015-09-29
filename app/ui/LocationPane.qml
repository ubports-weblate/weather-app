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

import QtQuick 2.4
import Ubuntu.Components 1.2
import Ubuntu.Components.ListItems 0.1 as ListItem
import "../components"
import "../data/suncalc.js" as SunCalc


ListView {
    id: mainPageWeekdayListView
    height: parent.height
    model: ListModel {

    }
    objectName: "locationListView"
    width: weatherApp.width

    /*
      Data properties
    */
    property string name
    property string currentTemp
    property string icon
    property string iconName

    property var hourlyForecastsData
    property string hourlyTempUnits

    property var todayData

    delegate: DayDelegate {
        day: model.day
        high: model.high
        image: model.image
        low: model.low

        modelData: model
    }
    header: Column {
        id: locationTop

        anchors {
            left: parent.left
            right: parent.right
            margins: units.gu(2)
        }
        spacing: units.gu(1)
        onHeightChanged: mainPageWeekdayListView.contentY = -height

        Row {  // spacing at top
            height: units.gu(1)
            width: parent.width
        }

        HeaderRow {
            id: headerRow
            locationName: mainPageWeekdayListView.name
        }

        HomeGraphic {
            id: homeGraphic
            icon: mainPageWeekdayListView.icon
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    homeGraphic.visible = false;
                }
            }
        }

        Loader {
            id: homeHourlyLoader
            active: !homeGraphic.visible
            asynchronous: true
            height: units.gu(32)
            source: "../components/HomeHourly.qml"
            visible: active
            width: parent.width
        }

        HomeTempInfo {
            id: homeTempInfo
            modelData: todayData
            now: mainPageWeekdayListView.currentTemp
        }

        // TODO: Migrate this to using the new SDK list item when possible.
        ListItem.ThinDivider {
            anchors {
                leftMargin: units.gu(-2);
                rightMargin: units.gu(-2)
            }
        }

        NumberAnimation {
            id: scrollToTopAnimation
            target: mainPageWeekdayListView;
            property: "contentY";
            duration: 200;
            easing.type: Easing.InOutQuad
            to: -height
        }

        Connections {
            target: locationPages
            onCurrentIndexChanged: {
                if (locationPages.currentIndex !== index) {
                    scrollToTopAnimation.start()
                } else {
                    mainPageWeekdayListView.contentY = -locationTop.height
                }
            }
        }
    }

    PullToRefresh {
        id: pullToRefresh
        refreshing: false
        onRefresh: {
            locationPages.loaded = false
            refreshing = true
            refreshData(false, true)
        }
    }

    function getDayData(data) {
        var tempUnits = settings.tempScale === "°C" ? "metric" : "imperial"

        return {
            day: formatTimestamp(data.date, 'dddd'),
            low: Math.round(data[tempUnits].tempMin).toString() + settings.tempScale,
            high: (data[tempUnits].tempMax !== undefined) ? Math.round(data[tempUnits].tempMax).toString() + settings.tempScale : "",
            image: (data.icon !== undefined && iconMap[data.icon] !== undefined) ? iconMap[data.icon] : "",
            condition: emptyIfUndefined(data.condition),
            chanceOfRain: emptyIfUndefined(data.propPrecip, "%"),
            humidity: emptyIfUndefined(data.humidity, "%"),
            sunrise: data.sunrise || SunCalc.SunCalc.getTimes(getDate(data.date), data.location.coord.lat, data.location.coord.lon).sunrise.toLocaleTimeString(),
            sunset: data.sunset || SunCalc.SunCalc.getTimes(getDate(data.date), data.location.coord.lat, data.location.coord.lon).sunset.toLocaleTimeString(),
            uvIndex: emptyIfUndefined(data.uv),
            wind: data[tempUnits].windSpeed === undefined || data.windDir === undefined
                        ? "" : Math.round(data[tempUnits].windSpeed) + settings.windUnits + " " + data.windDir
        };
    }

    function emptyIfUndefined(variable, append) {
        if (append === undefined) {
            append = ""
        }

        return variable === undefined ? "" : variable + append
    }

    /*
      Extracts values from the location weather data and puts them into the appropriate components
      to display them.

      Attention: Data access happens through "weatherApp.locationList[]" by index, since complex
      data in models will lead to type problems.
    */
    function renderData(index) {
        var data = weatherApp.locationsList[index],
                current = data.data[0].current,
                forecasts = data.data,
                forecastsLength = forecasts.length,
                hourlyForecasts = [];

        var tempUnits = settings.tempScale === "°C" ? "metric" : "imperial"

        // set general location data
        name = data.location.name;

        // set current temps and condition
        iconName = (current.icon) ? current.icon : "";
        icon = (imageMap[iconName] !== undefined) ? imageMap[iconName] : "";
        currentTemp = Math.round(current[tempUnits].temp).toString() + String("°");

        // reset days list
        // TODO: overwrite and trim to make the refresh smoother?
        mainPageWeekdayListView.model.clear()

        // set daily forecasts
        if(forecastsLength > 0) {
            for(var x=0;x<forecastsLength;x++) {
                // collect hourly forecasts if available
                if(forecasts[x].hourly !== undefined && forecasts[x].hourly.length > 0) {
                    hourlyForecasts = hourlyForecasts.concat(forecasts[x].hourly)
                }

                // Copy the coords of the location
                // so that sun{rise,set} work with OWM
                forecasts[x].location = {
                    coord: data.location.coord,
                };

                if (x === 0) {
                    // Store as tmp var so we can remove the condition
                    // therefore not showing it in the expandable
                    var tmpData = getDayData(forecasts[x]);
                    tmpData.condition = "";

                    // store today's data for later use
                    todayData = tmpData;
                } else {
                    // set daydata
                    mainPageWeekdayListView.model.append(getDayData(forecasts[x]));
                }
            }
        }

        // set data for hourly forecasts
        if(hourlyForecasts.length > 0) {
            hourlyForecastsData = hourlyForecasts;
            hourlyTempUnits = tempUnits;
        }
    }

    Component.onCompleted: renderData(index)
}
