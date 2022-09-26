//
//  SearchViewController.swift
//  MyWeather
//
//  Created by Tatiana Simmer on 06/08/2022.
//

import UIKit

class SearchViewController: UIViewController, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {

    @IBOutlet weak var CityTableView: UITableView!
    
    var current: CurrentWeather?
    var city = ""
    var unitIsCelsius = true
    let screenSize: CGRect = UIScreen.main.bounds
    var searchResultPlaces: [Place] = []
    
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
            return 3
        } else if tableView == searchResultTableView {
            return searchResultPlaces.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == CityTableView {
            guard let currentWeather = self.current else {
                return CityCell()
            }
            
            let cell = CityTableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath) as! CityCell
            cell.CityLabel.text = "\(self.city)"
            cell.SumUpLabel.text = "\(self.current?.weather[0].description.capitalized ?? "")"
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
            // TODO: Open the details for that city
        } else if tableView == searchResultTableView {
            tableView.deselectRow(at: indexPath, animated: true)
            
            let place: Place = searchResultPlaces[indexPath.row]
            // TODO: Open the weather for that city with buttons add and cancel
            print(place)
        }
    }
}
