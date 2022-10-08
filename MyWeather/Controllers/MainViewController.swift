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
    
    var slides:[Slide] = [];
    var places:[Place] = [];
    
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
    var contentWidth: CGFloat = 0.0
    let menuButton = UIButton()
    let searchButton = UIButton()

    
    let locationManager = CLLocationManager()
    var unitIsCelsius = true
    
    var searchViewController = SearchViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self

        createSlides()
        configurePageControl()

        let largeConfig = UIImage.SymbolConfiguration(scale: .large)
        menuButton.showsMenuAsPrimaryAction = true
        menuButton.tintColor = .white
        menuButton.setImage(UIImage(systemName: "ellipsis.circle", withConfiguration: largeConfig), for: .normal)
        menuButton.menu = menu
        menuButton.frame = CGRect(x: screenSize.width - 60.0, y: 40.0, width: 50, height: 50)
        view.addSubview(menuButton)
        
        setupLocation()
        setUpSearchButton()
        view.addSubview(searchButton)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setUpSearchButton()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = Int(pageNumber)
    }
    
    func configurePageControl() {
        pageControl.numberOfPages = slides.count
        pageControl.currentPage = 0
    }
    
    func createSlides() {
        for place in places {
            requestWeatherForLocation(place: place)
        }
    }
    
    func addANewSlide(place: Place) {
        
        let slide:Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        
        places.append(place)
        slides.append(slide)

        slide.table.register(HourlyContainerCell.nib(), forCellReuseIdentifier: HourlyContainerCell.identifier)
        slide.table.register(DailyContainerCell.nib(), forCellReuseIdentifier: DailyContainerCell.identifier)
        slide.table.delegate = self
        slide.table.dataSource = self
        slide.table.allowsSelection = false
        slide.table.backgroundColor = .clear
        slide.table.reloadData()
        slide.table.tableHeaderView = self.createTableHeader(place: place)
        
        let xCoordinate = screenSize.width * CGFloat(slides.count - 1)
        contentWidth += screenSize.width
        slide.frame = CGRect(x: xCoordinate, y: 0, width: screenSize.width, height: view.frame.height)
        scrollView.addSubview(slide)
        slide.center = CGPointMake(scrollView.bounds.size.width * 0.5 + screenSize.width * CGFloat(slides.count - 1), slide.center.y);
        scrollView.contentSize = CGSize(width: contentWidth, height: view.frame.height)
        pageControl.numberOfPages = slides.count
    }
    
    func changeTempUnit(unit: String) {
        unitIsCelsius = unit == "Celsius" ? true : false
    
        // Reload tableview
        DispatchQueue.main.async {
            for i in 0..<self.slides.count {
                self.slides[i].table.reloadData()
                self.slides[i].table.tableHeaderView = self.createTableHeader(place: self.places[i])
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
    
    func setUpSearchButton() {
        searchButton.frame = CGRect(x: screenSize.width - 60.0, y: screenSize.height - 70.0, width: 50, height: 50)
        searchButton.tintColor = .white
        let largeConfig = UIImage.SymbolConfiguration(scale: .large)
        searchButton.setImage(UIImage(systemName:"list.bullet", withConfiguration: largeConfig), for: .normal)
        
        searchViewController = storyboard?.instantiateViewController(identifier: "SearchViewId") as! SearchViewController
        
        searchButton.addTarget(self, action: #selector(goSearchView), for: UIControl.Event.touchUpInside)
    }
    
    @objc func goSearchView() {
        // Go to SearchViewController and passing variables from this controller
        searchViewController.modalPresentationStyle = .fullScreen
        searchViewController.places = places
        searchViewController.unitIsCelsius = unitIsCelsius
        searchViewController.pageControl = pageControl
        self.present(searchViewController, animated: true, completion: nil)
    }
    
    func setupLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !locations.isEmpty {
            locationManager.stopUpdatingLocation()
            let geocoder = CLGeocoder()
            if let location = locations.first {
                geocoder.reverseGeocodeLocation(location) { [self] (placemarks, error) in
                    if let error = error {
                        debugPrint(error.localizedDescription)
                    }
                    if let placemarks = placemarks {
                        if placemarks.count > 0 {
                            let placemark = placemarks[0]
                            if let city = placemark.locality {
                                let place = Place(name: city, lat: location.coordinate.latitude, lon: location.coordinate.longitude)
                                self.requestWeatherForLocation(place: place)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func requestWeatherForLocation(place: Place) {
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String
        
        guard let key = apiKey, !key.isEmpty else {
            print("API key does not exist")
            return
        }
        
        guard let url = URL(string: "https://api.openweathermap.org/data/2.5/onecall?lat=\(place.lat)&lon=\(place.lon)&appid=\(key)") else { fatalError("Missing URL") }
        
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
            
            var newPlace = Place(name: place.name, lat: place.lat, lon: place.lon)
            newPlace.current = result.current
            newPlace.daily = result.daily
            newPlace.hourly = result.hourly
                        
            // Create slide table for that place
            DispatchQueue.main.async {
                self.addANewSlide(place: newPlace)
            }
        }).resume()
    }
    
    func createTableHeader(place: Place) -> UIView {
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
        
        locationLabel.text = place.name
        locationLabel.textColor = UIColor.white
        locationLabel.font = UIFont(name: "Helvetica", size: 30)
                
        tempLabel.text = convertTemp(temp: place.current.temp, from: UnitTemperature.kelvin, to: self.unitIsCelsius ? UnitTemperature.celsius : UnitTemperature.fahrenheit)
        tempLabel.textColor = UIColor.white
        tempLabel.font = UIFont(name: "Helvetica-Bold", size: 32)
        summaryLabel.text = place.current.weather[0].description.capitalized
        summaryLabel.textColor = UIColor.white
        summaryLabel.font = UIFont(name: "Helvetica", size: 20)
        if let weatherInfo = place.current.weather.first {
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
        for slide in slides {
            if slide.table == tableView {
                if indexPath.section == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: HourlyContainerCell.identifier, for: indexPath) as! HourlyContainerCell
                    cell.configure(with: places[indexPath.row].hourly, unitIsCelsius: self.unitIsCelsius )
                    cell.backgroundColor = UIColor.clear
                    return cell
                } else if indexPath.section == 1 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: DailyContainerCell.identifier, for: indexPath) as! DailyContainerCell
                    cell.configure(with: places[indexPath.row].daily, unitIsCelsius: self.unitIsCelsius)
                    cell.backgroundColor = UIColor.clear
                    return cell
                }
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 145
        }
        return CGFloat((65) * places[0].daily.count)
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
