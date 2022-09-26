//
//  HourlyCollectionViewCell.swift
//  MyWeather
//
//  Created by Tatiana Simmer on 28/07/2022.
//

import UIKit

class HourlyCollectionViewCell: UICollectionViewCell, UICollectionViewDelegateFlowLayout {

    static let identifier = "HourlyCollectionViewCell"

    static func nib() -> UINib {
        return UINib(nibName: "HourlyCollectionViewCell",
                     bundle: nil)
    }

    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var tempLabel: UILabel!
    @IBOutlet var hourLabel: UILabel!

    func configure(with model: HourlyWeather, unitIsCelsius: Bool) {
        let date = NSDate(timeIntervalSince1970: TimeInterval(model.dt))
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = "HH"
        let hourString = dayTimePeriodFormatter.string(from: date as Date)
        
        self.hourLabel.text = "\(hourString)"
        self.tempLabel.text =  convertTemp(temp: model.temp, from: UnitTemperature.kelvin, to: unitIsCelsius ? UnitTemperature.celsius : UnitTemperature.fahrenheit)
        self.iconImageView.contentMode = .scaleAspectFit
        if let weatherInfo = model.weather.first {
            let icon = weatherInfo.icon.lowercased()
            self.iconImageView.image = UIImage(named: icon)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
