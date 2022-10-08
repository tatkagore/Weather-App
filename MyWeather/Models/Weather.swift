//
//  Weather.swift
//  MyWeather
//
//  Created by Tatiana Simmer on 27/07/2022.
//

import Foundation
import CoreLocation

struct WeatherResponse: Codable {
    let lat: Double
    let lon: Double
    let timezone: String
    let current: CurrentWeather
    let hourly: [HourlyWeather]
    let daily: [DailyWeather]
}

struct Place: Codable {
    var name: String = ""
    var identifier: String = ""
    var lat: Double = 0.0
    var lon: Double = 0.0
    var timezone: String = ""
    var current: CurrentWeather = CurrentWeather()
    var hourly: [HourlyWeather] = [HourlyWeather()]
    var daily: [DailyWeather] = [DailyWeather()]
}

struct CurrentWeather: Codable {
    var dt: Int = 0
    var sunrise: Int = 0
    var sunset: Int = 0
    var temp: Double = 0.0
    var feels_like: Double = 0.0
    var pressure: Int = 0
    var humidity: Int = 0
    var dew_point: Double = 0.0
    var uvi: Double = 0.0
    var clouds: Int = 0
    var wind_speed: Double = 0.0
    var wind_deg: Int = 0
    var weather = [Weather()]
}

struct Weather: Codable {
    var id: Int = 0
    var main: String = ""
    var description: String = ""
    var icon: String = ""
}

struct DailyWeather: Codable {
    var dt: Int = 0
    var sunrise: Int = 0
    var sunset: Int = 0
    var temp = Temperature()
    var feels_like = Feels_Like()
    var pressure: Int = 0
    var humidity: Int = 0
    var dew_point: Double = 0.0
    var wind_speed: Double = 0.0
    var wind_deg: Int = 0
    var weather = [Weather()]
    var clouds: Int = 0
    var uvi: Double = 0.0
}

struct HourlyWeather: Codable {
    var dt: Int = 0
    var temp: Double = 0.0
    var feels_like: Double = 0.0
    var pressure: Int = 0
    var humidity: Int = 0
    var dew_point: Double = 0.0
    var clouds: Int = 0
    var wind_speed: Double = 0.0
    var wind_deg: Int = 0
    var weather = [Weather()]
}

struct Temperature: Codable {
    var day: Double = 0.0
    var min: Double = 0.0
    var max: Double = 0.0
    var night: Double = 0.0
    var eve: Double = 0.0
    var morn: Double = 0.0
}

struct Feels_Like: Codable {
    var day: Double = 0.0
    var night: Double = 0.0
    var eve: Double = 0.0
    var morn: Double = 0.0
}
