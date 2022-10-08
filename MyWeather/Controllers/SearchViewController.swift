//
//  SearchViewController.swift
//  MyWeather
//
//  Created by Tatiana Simmer on 06/08/2022.
//

import UIKit

class SearchViewController: UIViewController, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {

    @IBOutlet weak var CityTableView: UITableView!
    
    var pageControl: UIPageControl!
    var unitIsCelsius = true
    let screenSize: CGRect = UIScreen.main.bounds
    var searchResultPlaces: [Place] = []
    var places: [Place] = []
    
    let searchVC = UISearchController()
    let navBar = UINavigationBar()
    let navItem = UINavigationItem()
    let searchResultTableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        table.backgroundView = UIView()
        table.backgroundView?.backgroundColor = .black
        return table
    }()
    
    let newPlaceViewController = NewPlaceViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navBar.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: 200.0)
        navBar.backgroundColor = .black
        navBar.barStyle = .black
        navBar.barTintColor = .white
        navBar.prefersLargeTitles = true
        
        let textFieldInsideSearchBar = searchVC.searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = .white
        
        searchVC.searchBar.placeholder = "Search for a city or airport"
        searchVC.searchBar.barStyle = .black
        searchVC.searchBar.tintColor = .white
        searchVC.searchBar.frame = CGRect(x: 0.0, y: 44.0, width: screenSize.width, height: 44.0)
        searchVC.searchResultsUpdater = self
        searchVC.delegate = self
        searchVC.searchBar.delegate = self
        
        navItem.title = "Weather"
        navItem.searchController = searchVC
        navBar.items = [navItem]
        view.addSubview(navBar)
        
        searchResultTableView.frame = CGRect(x: 0.0, y: 200, width: screenSize.width, height: screenSize.height)
        searchResultTableView.delegate = self
        searchResultTableView.dataSource = self
        searchResultTableView.isHidden = true
        view.addSubview(searchResultTableView)

        CityTableView.delegate = self
        CityTableView.dataSource = self
        CityTableView.separatorStyle = .none
        CityTableView.showsVerticalScrollIndicator = false
        CityTableView.frame = CGRect(x: 0, y: navBar.bounds.maxY, width: screenSize.width, height: screenSize.height)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text,
              !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResultTableView.isHidden = true
            return
        }
        
        GooglePlacesManager.shared.findPlaces(query: query) { result in
            switch result {
            case .success(let newPlaces):
                self.searchResultPlaces = newPlaces
                self.searchResultTableView.isHidden = false
                self.searchResultTableView.reloadData()
            case .failure(let error):
                print(error)
            }
        }
    }
}

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == CityTableView {
            return 130
        } else if tableView == searchResultTableView {
            return 50
        }
        return 50
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == CityTableView {
            return places.count
        } else if tableView == searchResultTableView {
            return searchResultPlaces.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == CityTableView {
            
            let place = places[indexPath.row]
            let currentWeather = place.current
            
            let cell = CityTableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath) as! CityCell
            
            if indexPath.row == 0 {
                cell.Title.text = "My Location"
                cell.Subtitle.text = "\(place.name)"
            } else {
                cell.Title.text = "\(place.name)"
                // TODO : Local Time
                cell.Subtitle.text = ""
            }
            
            cell.SumUpLabel.text = "\(place.current.weather[0].description.capitalized)"
            cell.TempLabel.text = "\(convertTemp(temp: currentWeather.temp, from: UnitTemperature.kelvin, to: self.unitIsCelsius ? UnitTemperature.celsius : UnitTemperature.fahrenheit))"
            cell.FeelsLikeLabel.text =  "Feels like: \(convertTemp(temp: currentWeather.feels_like, from: UnitTemperature.kelvin, to: self.unitIsCelsius ? UnitTemperature.celsius : UnitTemperature.fahrenheit))"
            cell.CityView.layer.cornerRadius = 20
            return cell
            
        } else if tableView == searchResultTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = searchResultPlaces[indexPath.row].name
            cell.backgroundColor = .black
            cell.textLabel?.textColor = .white
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == CityTableView {
            // Go to that place's slide
            self.pageControl.currentPage = indexPath.row
            weak var mainViewController = self.presentingViewController as? MainViewController
            mainViewController?.scrollView.contentOffset.x = screenSize.width * CGFloat(indexPath.row)
            self.dismiss(animated: true, completion: nil)
        } else if tableView == searchResultTableView {
            self.searchVC.isActive = false

            var place: Place = searchResultPlaces[indexPath.row]
            
            GooglePlacesManager.shared.resolveLocation(place: place) { [self] result in
                switch result {
                case .success(let coordinates):
                    place.lat = coordinates.latitude
                    place.lon = coordinates.longitude
                    place.name = String(place.name.split(separator: ",")[0])
                    
                    // Open the weather for that city with buttons add and cancel
                    self.newPlaceViewController.modalPresentationStyle = .fullScreen
                    self.newPlaceViewController.place = place
                    self.newPlaceViewController.unitIsCelsius = unitIsCelsius
                    self.present(newPlaceViewController, animated: false, completion: nil)
                case .failure(let error):
                    print(error)
                }
            }
                
        }
    }
}
