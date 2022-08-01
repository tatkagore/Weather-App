//
//  DailyCollectionViewCell.swift
//  MyWeather
//
//  Created by Tatiana Simmer on 28/07/2022.
//

import UIKit

class DailyCollectionViewCell: UICollectionViewCell, UICollectionViewDelegateFlowLayout {
    
    static let identifier = "DailyCollectionViewCell"

    static func nib() -> UINib {
        return UINib(nibName: "DailyCollectionViewCell",
                     bundle: nil)
    }

    @IBOutlet var dayLabel: UILabel!
    @IBOutlet var highTempLabel: UILabel!
    @IBOutlet var lowTempLabel: UILabel!
    @IBOutlet var iconImageView: UIImageView!

    func configure(with model: DailyWeather, unitIsCelsius: Bool) {
        self.highTempLabel.textAlignment = .center
        self.lowTempLabel.textAlignment = .center
        self.lowTempLabel.text = convertTemp(temp: model.temp.min, from: UnitTemperature.kelvin, to: unitIsCelsius ? UnitTemperature.celsius : UnitTemperature.fahrenheit)
        self.highTempLabel.text = convertTemp(temp: model.temp.max, from: UnitTemperature.kelvin, to: unitIsCelsius ? UnitTemperature.celsius : UnitTemperature.fahrenheit)
        self.dayLabel.text = getDayForDate(Date(timeIntervalSince1970: Double(model.dt)))
        self.iconImageView.contentMode = .scaleAspectFit
        
        if let weatherInfo = model.weather.first {
            let icon = weatherInfo.icon.lowercased()
            self.iconImageView.image = UIImage(named: icon)
        }
    }
    
    func getDayForDate(_ date: Date?) -> String {
        guard let inputDate = date else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Monday
        return formatter.string(from: inputDate)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

}
