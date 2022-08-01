//
//  ViewController.swift
//  MyWeather
//
//  Created by Tatiana Simmer on 21/07/2022.
//

import UIKit
import CoreLocation


class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    
    @IBOutlet var table: UITableView!
    @IBOutlet var navbar: UINavigationBar!
    @IBOutlet var menuButton: UIButton!
    @IBOutlet var celsiusButton: UIMenuElement!
    @IBOutlet var fahrenheitButton: UIMenuElement!
    
    @IBAction func changeTemperaturePreference(_ sender: UIMenuElement) {
        
//        NOT WORKING
//        celsiusButton = UIAction(title: "Celsius", state: sender.title == "Celsius" ? .on : .off, handler: {(_) in })
//        fahrenheitButton = UIAction(title: "Celsius", state: sender.title ==  "Celsius" ? .off : .on, handler: {(_) in })

        unitIsCelsius = sender.title == "Celsius" ? true : false
        DispatchQueue.main.async {
            self.table.reloadData()
            self.table.tableHeaderView = self.createTableHeader()
        }
    }
    
    var dailyModels = [DailyWeather]()
    var hourlyModels = [HourlyWeather]()
    
    var city = ""
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var current: CurrentWeather?
    var unitIsCelsius = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Register 2 cells
        table.register(HourlyContainerCell.nib(), forCellReuseIdentifier: HourlyContainerCell.identifier)
        table.register(DailyContainerCell.nib(), forCellReuseIdentifier: DailyContainerCell.identifier)
        
        table.delegate = self
        table.dataSource = self
        
        table.backgroundColor = .clear
        navbar.backgroundColor = .clear
        navbar.setBackgroundImage(UIImage(), for: .default)
        navbar.shadowImage = UIImage()
        navbar.isTranslucent = true
        self.view.backgroundColor = .clear
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupLocation()
    }
    
    // Location
    func setupLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !locations.isEmpty, currentLocation == nil  {
            currentLocation = locations.first
            locationManager.stopUpdatingLocation()
            requestWeatherForLocation()
            let geocoder = CLGeocoder()
            if let location = currentLocation {
                geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                    if let error = error {
                        debugPrint(error.localizedDescription)
                    }
                    if let placemarks = placemarks {
                        if placemarks.count > 0 {
                            let placemark = placemarks[0]
                            if let city = placemark.locality {
                                self.city = city
                            }
                        }
                    }
                }
            }
        }
    }
    
    func requestWeatherForLocation() {
        guard let currentLocation = currentLocation else {
            return
        }
        let long = currentLocation.coordinate.longitude
        let lat = currentLocation.coordinate.latitude
        
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String
        
        guard let key = apiKey, !key.isEmpty else {
            print("API key does not exist")
            return
        }
        
        guard let url = URL(string: "https://api.openweathermap.org/data/2.5/onecall?lat=\(lat)&lon=\(long)&appid=\(key)") else { fatalError("Missing URL") }
        
        URLSession.shared.dataTask(with: url, completionHandler: {data, response, error in
            // Validation
            guard let data = data, error == nil else {
                print("something went wrong")
                return
            }
            
            //convert data to models/some object
            var json: WeatherResponse?
            do {
                json = try JSONDecoder().decode(WeatherResponse.self, from: data)
            }
            catch {
                print("error: \(error)")
            }
            
            guard let result = json else {
                return
            }
                
            self.dailyModels = result.daily
            self.current = result.current
            self.hourlyModels = result.hourly

            // Update user interface
            DispatchQueue.main.async {
                self.table.reloadData()
                self.table.tableHeaderView = self.createTableHeader()
            }
        }).resume()
    }
    
    func createTableHeader() -> UIView {
        let headerView = UIView(frame: CGRect(x: 0, y: 20, width: view.frame.size.width, height: view.frame.size.width))
        let locationLabel = UILabel(frame: CGRect(x: 10, y: 30, width: view.frame.size.width-20, height: headerView.frame.size.height/5))
        let summaryLabel = UILabel(frame: CGRect(x: 10, y: 20+locationLabel.frame.size.height, width: view.frame.size.width-20, height: headerView.frame.size.height/5))
        let imageView = UIImageView(frame: CGRect(x: 10, y: 20+locationLabel.frame.size.height+summaryLabel.frame.size.height, width: view.frame.size.width-20, height: headerView.frame.size.height/5));
        let tempLabel = UILabel(frame: CGRect(x: 10, y: 20+locationLabel.frame.size.height+summaryLabel.frame.size.height+imageView.frame.size.height, width: view.frame.size.width-20, height: headerView.frame.size.height*2/5))
        
        headerView.addSubview(locationLabel)
        headerView.addSubview(tempLabel)
        headerView.addSubview(summaryLabel)
        tempLabel.textAlignment = .center
        locationLabel.textAlignment = .center
        summaryLabel.textAlignment = .center
        
        locationLabel.text = self.city
        locationLabel.textColor = UIColor.white
        locationLabel.font = UIFont(name: "Helvetica", size: 30)
        
        guard let currentWeather = self.current else {
            return UIView()
        }
        
        tempLabel.text = convertTemp(temp: currentWeather.temp, from: UnitTemperature.kelvin, to: self.unitIsCelsius ? UnitTemperature.celsius : UnitTemperature.fahrenheit)
        tempLabel.textColor = UIColor.white
        tempLabel.font = UIFont(name: "Helvetica-Bold", size: 32)
        summaryLabel.text = self.current?.weather[0].description.capitalized
        summaryLabel.textColor = UIColor.white
        summaryLabel.font = UIFont(name: "Helvetica", size: 20)
        if let weatherInfo = currentWeather.weather.first {
            imageView.image = UIImage(named: weatherInfo.icon.lowercased())
            imageView.contentMode = .scaleAspectFit
            headerView.addSubview(imageView)
        }
        return headerView
    }
    
    //Table
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: HourlyContainerCell.identifier, for: indexPath) as! HourlyContainerCell
            cell.configure(with: hourlyModels, unitIsCelsius: self.unitIsCelsius )
            cell.backgroundColor = UIColor.clear
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: DailyContainerCell.identifier, for: indexPath) as! DailyContainerCell
        cell.configure(with: dailyModels, unitIsCelsius: self.unitIsCelsius)
        cell.backgroundColor = UIColor.clear
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 145
        }
        return CGFloat((65) * dailyModels.count)
    }
}

func convertTemp(temp: Double, from inputTempType: UnitTemperature, to outputTempType: UnitTemperature) -> String {
    let mf = MeasurementFormatter()
    mf.numberFormatter.maximumFractionDigits = 0
    mf.unitOptions = .providedUnit
    let input = Measurement(value: temp, unit: inputTempType)
    let output = input.converted(to: outputTempType)
    return mf.string(from: output)
}
