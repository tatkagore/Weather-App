 //
//  CityCell.swift
//  MyWeather
//
//  Created by Tatiana Simmer on 11/08/2022.
//

import UIKit

class CityCell: UITableViewCell {

    @IBOutlet weak var Title: UILabel!
    @IBOutlet weak var CityView: UIView!
    @IBOutlet weak var Subtitle: UILabel!
    @IBOutlet weak var SumUpLabel: UILabel!
    @IBOutlet weak var TempLabel: UILabel!
    @IBOutlet weak var FeelsLikeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
