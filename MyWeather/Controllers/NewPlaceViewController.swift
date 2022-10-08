//
//  NewPlaceViewController.swift
//  MyWeather
//
//  Created by Tatiana Simmer on 08/10/2022.
//

import UIKit

class NewPlaceViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let screenSize: CGRect = UIScreen.main.bounds
    var unitIsCelsius = true
    var slide = Slide()
    var place = Place()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 52/255, green: 109/255, blue: 179/255, alpha: 0.9)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requestWeatherForLocation(place: place)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        slide = Slide()
        view.viewWithTag(666)?.removeFromSuperview()
    }
    
    func setUpButtons() {
        let cancelButton = UIButton(type: .custom)
        cancelButton.frame = CGRect(x: 10.0, y: 50.0, width: 70, height: 50)
        cancelButton.tintColor = .white
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancel), for: UIControl.Event.touchUpInside)
        view.addSubview(cancelButton)
        
        let addButton = UIButton(type: .custom)
        addButton.frame = CGRect(x: screenSize.width - 60.0, y: 50.0, width: 50, height: 50)
        addButton.tintColor = .white
        addButton.setTitle("Add", for: .normal)
        addButton.addTarget(self, action: #selector(add), for: UIControl.Event.touchUpInside)
        view.addSubview(addButton)
    }
    
    @objc func add() {
        weak var searchViewController = self.presentingViewController as? SearchViewController
        weak var mainViewController = searchViewController?.presentingViewController as? MainViewController
        self.dismiss(animated: true)
        searchViewController?.dismiss(animated: false)
        mainViewController?.addANewSlide(place: place)
        let placesCount = mainViewController?.places.count ?? 1
        mainViewController?.pageControl.currentPage = placesCount - 1
        mainViewController?.scrollView.contentOffset.x = screenSize.width * CGFloat(placesCount - 1)
    }
    
    @objc func cancel() {
        self.dismiss(animated: true)
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
                self.place = newPlace
                self.createSubView()
            }
        }).resume()
    }
    
    func createSubView() {
        slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide

        slide.table.register(HourlyContainerCell.nib(), forCellReuseIdentifier: HourlyContainerCell.identifier)
        slide.table.register(DailyContainerCell.nib(), forCellReuseIdentifier: DailyContainerCell.identifier)
        slide.table.delegate = self
        slide.table.dataSource = self
        slide.table.allowsSelection = false
        slide.table.backgroundColor = .clear
        slide.table.reloadData()
        slide.table.tableHeaderView = self.createTableHeader(place: place)
        
        slide.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: view.frame.height)
        slide.tag = 666
        view.addSubview(slide)
        slide.center = CGPointMake(screenSize.width * 0.5, slide.center.y);
        setUpButtons()
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
        
        let currentWeather = place.current
        
        tempLabel.text = convertTemp(temp: currentWeather.temp, from: UnitTemperature.kelvin, to: self.unitIsCelsius ? UnitTemperature.celsius : UnitTemperature.fahrenheit)
        tempLabel.textColor = UIColor.white
        tempLabel.font = UIFont(name: "Helvetica-Bold", size: 32)
        summaryLabel.text = place.current.weather[0].description.capitalized
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
            cell.configure(with: place.hourly, unitIsCelsius: self.unitIsCelsius )
            cell.backgroundColor = UIColor.clear
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: DailyContainerCell.identifier, for: indexPath) as! DailyContainerCell
            cell.configure(with: place.daily, unitIsCelsius: self.unitIsCelsius)
            cell.backgroundColor = UIColor.clear
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 145
        }
        return CGFloat((65) * place.daily.count)
    }

}
