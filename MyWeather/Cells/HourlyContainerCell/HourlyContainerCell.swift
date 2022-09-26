//
//  HourlyContainerCell.swift
//  MyWeather
//
//  Created by Tatiana Simmer on 21/07/2022.
//

import UIKit

class HourlyContainerCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet var collectionView: UICollectionView!

    var models = [HourlyWeather]()
    var unitIsCelsius = true

    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.register(HourlyCollectionViewCell.nib(), forCellWithReuseIdentifier: HourlyCollectionViewCell.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.layer.cornerRadius = 10.0
        collectionView.alpha = 0.9
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    static let identifier = "HourlyContainerCell"

    static func nib() -> UINib {
        return UINib(nibName: "HourlyContainerCell",
                     bundle: nil)
    }

    func configure(with models: [HourlyWeather], unitIsCelsius: Bool) {
        self.models = models
        self.unitIsCelsius = unitIsCelsius 
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 100)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return models.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HourlyCollectionViewCell.identifier, for: indexPath) as! HourlyCollectionViewCell
        cell.configure(with: models[indexPath.row], unitIsCelsius: unitIsCelsius)
        return cell
    }
    
}
