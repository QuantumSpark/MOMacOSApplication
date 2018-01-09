//
//  ViewController.swift
//  MacOSApplication
//
//  Created by James Park on 2018-01-02.
//  Copyright © 2018 James Park. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var collectionView: NSCollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        for _ in 0..<28 {
             TCPSocketManager.sharedManager.currentStashedData.append(DataIPad())
        }
        
        configureCollectionView()
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    fileprivate func configureCollectionView() {
        // 1
        let flowLayout = NSCollectionViewFlowLayout()


        flowLayout.sectionInset = NSEdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)
        flowLayout.minimumInteritemSpacing = 20.0
        flowLayout.minimumLineSpacing = 20.0
        flowLayout.scrollDirection = .horizontal

        let horizontalSpacing = flowLayout.minimumLineSpacing
        flowLayout.itemSize = CGSize(width: 500, height: 800)

        collectionView.collectionViewLayout = flowLayout
        // 2
        view.wantsLayer = true
        // 3
        collectionView.layer?.backgroundColor = NSColor.white.cgColor
    }


}

extension ViewController : NSCollectionViewDataSource {

    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 28
    }

    func collectionView(_ itemForRepresentedObjectAtcollectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {

        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CollectionViewItem"), for: indexPath) as! CollectionViewItem

        item.id = indexPath.item

        item.dataIPad = TCPSocketManager.sharedManager.currentStashedData[indexPath.item]

        TCPSocketManager.sharedManager.currentStashedData[indexPath.item].id = indexPath.item
        return item
    }

}

