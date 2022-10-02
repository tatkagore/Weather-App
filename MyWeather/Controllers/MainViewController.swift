//
//  MainViewController.swift
//  MyWeather
//
//  Created by Tatiana Simmer on 24/09/2022.
//

import UIKit
import CoreLocation
import MapKit

class MainViewController: UIViewController, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var pageControl: UIPageControl!
    
    private lazy var celsius = UIAction(title: "Celsius", image: UIImage(named: "celsius"), state: .on) { action in
        self.changeTempUnit(unit: "Celsius")
    }
    
    private lazy var fahrenheit = UIAction(title: "Fahrenheit", image: UIImage(named: "fahrenheit"), state: .off) { action in
        self.changeTempUnit(unit: "Fahrenheit")
    }
    
    private lazy var elements: [UIAction] = [celsius, fahrenheit]
    private lazy var menu = UIMenu(title: "Choose units of measure", children: elements)
    
    let screenSize: CGRect = UIScreen.main.bounds
    
    var dailyModels = [DailyWeather]()
    var hourlyModels = [HourlyWeather]()
    
    var city = ""
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var current: CurrentWeather?
    var unitIsCelsius = true
    var slides:[Slide] = [];
    var places:[Place] = [Place(name: "Current location", identifier: "0")];
    
    var contentWidth: CGFloat = 0.0
    let menuButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self

        createSlides()
        setupSlideScrollView()
        configurePageControl()

        let largeConfig = UIImage.SymbolConfiguration(scale: .large)
        menuButton.showsMenuAsPrimaryAction = true
        menuButton.tintColor = .white
        menuButton.setImage(UIImage(systemName: "ellipsis.circle", withConfiguration: largeConfig), for: .normal)
        menuButton.menu = menu
        menuButton.frame = CGRect(x: screenSize.width - 60.0, y: 40.0, width: 50, height: 50)
        view.addSubview(menuButton)
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = Int(pageNumber)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupLocation()
        let toolbarRightButton = setUpSearchButton()
        view.addSubview(toolbarRightButton)
    }
    
    func configurePageControl() {
        pageControl.numberOfPages = slides.count
        pageControl.currentPage = 0
    }
    
    func createSlides() {
        for _ in 0...1 {
            let slide:Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide

            slide.table.register(HourlyContainerCell.nib(), forCellReuseIdentifier: HourlyContainerCell.identifier)
            slide.table.register(DailyContainerCell.nib(), forCellReuseIdentifier: DailyContainerCell.identifier)
            
            slide.table.delegate = self
            slide.table.dataSource = self
            slide.table.allowsSelection = false
            slide.table.backgroundColor = .clear
            
            slides.append(slide)
        }
    }
    
    func setupSlideScrollView() {
        for i in 0 ..< slides.count {
            let xCoordinate = screenSize.width * CGFloat(i)
            contentWidth += screenSize.width
            print(screenSize.width, xCoordinate)
            slides[i].frame = CGRect(x: xCoordinate, y: 0, width: screenSize.width, height: view.frame.height)
            scrollView.addSubview(slides[i])
            slides[i].center = CGPointMake(scrollView.bounds.size.width * 0.5 + screenSize.width * CGFloat(i), slides[i].center.y);
        }
        scrollView.contentSize = CGSize(width: contentWidth, height: view.frame.height)
    }
    
    func changeTempUnit(unit: String) {
        unitIsCelsius = unit == "Celsius" ? true : false
    
        // Reload tableview
        DispatchQueue.main.async {
            for slide in self.slides {
                slide.table.reloadData()
                slide.table.tableHeaderView = self.createTableHeader()
            }
        }
        
        // Recreate menu with good states
        celsius = UIAction(title: "Celsius", image: UIImage(named: "celsius"), state: unitIsCelsius ? .on : .off) { action in
            self.changeTempUnit(unit: "Celsius")
        }
        fahrenheit = UIAction(title: "Fahrenheit", image: UIImage(named: "fahrenheit"), state: unitIsCelsius ? .off : .on) { action in
            self.changeTempUnit(unit: "Fahrenheit")
        }
        elements = [celsius, fahrenheit]
        menu = UIMenu(title: "Choose units of measure", children: elements)
        menuButton.menu = menu
    }
    
    func setUpSearchButton() -> UIButton {
        let btn = UIButton(type: .custom)
        btn.frame = CGRect(x: screenSize.width - 60.0, y: screenSize.height - 70.0, width: 50, height: 50)
        btn.tintColor = .white
        let largeConfig = UIImage.SymbolConfiguration(scale: .large)
        btn.setImage(UIImage(systemName:"list.bullet", withConfiguration: largeConfig), for: .normal)
        btn.addTarget(self, action: #selector(goSearchView), for: UIControl.Event.touchUpInside)
        
        return btn
    }
    
    @objc func goSearchView() {
        // Go to SearchViewController and passing variables from this controller
        let story = UIStoryboard(name: "Main", bundle: nil)
        let controller = story.instantiateViewController(identifier: "SearchViewId") as! SearchViewController
        controller.modalPresentationStyle = .fullScreen
        controller.current = self.current
        controller.city = self.city
        controller.unitIsCelsius = self.unitIsCelsius
        self.present(controller, animated: true, completion: nil)
    }
    
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
            guard let data = data, error == nil else {
                print(error as Any)
                return
            }
            
            // Convert data to models/some object
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
            
            // Update current location slide
            DispatchQueue.main.async {
                for slide in self.slides {
                    slide.table.reloadData()
                    slide.table.tableHeaderView = self.createTableHeader()
                }
            }
        }).resume()
    }
    
    func createTableHeader() -> UIView {
        let headerView = UIView(frame: CGRect(x: 0, y: 20, width: screenSize.width, height: screenSize.width))
        let locationLabel = UILabel(frame: CGRect(x: 10, y: 30, width: screenSize.width, height: headerView.frame.size.height/5))
        let summaryLabel = UILabel(frame: CGRect(x: 10, y: 20+locationLabel.frame.size.height, width: screenSize.width, height: headerView.frame.size.height/5))
        let imageView = UIImageView(frame: CGRect(x: 10, y: 20+locationLabel.frame.size.height+summaryLabel.frame.size.height, width: screenSize.width, height: headerView.frame.size.height/5));
        let tempLabel = UILabel(frame: CGRect(x: 10, y: 20+locationLabel.frame.size.height+summaryLabel.frame.size.height+imageView.frame.size.height, width: screenSize.width, height: headerView.frame.size.height*2/5))
        
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
    
    mf.unitOptions = .temperatureWithoutUnit
    
    let input = Measurement(value: temp,  unit: inputTempType)
    let output = input.converted(to: outputTempType)
    return mf.string(from: output)
}
