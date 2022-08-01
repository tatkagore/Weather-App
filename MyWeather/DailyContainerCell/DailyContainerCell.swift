//
//  DailyContainerCell.swift
//  MyWeather
//
//  Created by Tatiana Simmer on 21/07/2022.
//

import UIKit

class DailyContainerCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet var collectionView: UICollectionView!

    var models = [DailyWeather]()
    var unitIsCelsius = true

    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.register(DailyCollectionViewCell.nib(), forCellWithReuseIdentifier: DailyCollectionViewCell.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.layer.cornerRadius = 10.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    static let identifier = "DailyContainerCell"

    static func nib() -> UINib {
        return UINib(nibName: "DailyContainerCell",
                     bundle: nil)
    }

    func configure(with models: [DailyWeather], unitIsCelsius: Bool) {
        self.models = models
        self.unitIsCelsius = unitIsCelsius 
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 300, height: 50)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return models.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DailyCollectionViewCell.identifier, for: indexPath) as! DailyCollectionViewCell
        cell.configure(with: models[indexPath.row], unitIsCelsius: unitIsCelsius)
        return cell
    }
}
