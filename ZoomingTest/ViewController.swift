//
//  ViewController.swift
//  ZoomingTest
//
//  Created by Kyohei Ito on 2015/07/17.
//  Copyright © 2015年 Kyohei Ito. All rights reserved.
//

import UIKit

extension UIEdgeInsets {
    static var zeroInsets: UIEdgeInsets {
        return UIEdgeInsets(all: 0)
    }
    
    init(all inset: CGFloat) {
        self.init(top: inset, left: inset, bottom: inset, right: inset)
    }
    
    init(horizontal: CGFloat, vertical: CGFloat) {
        self.init(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }
}

extension CGSize {
    /// size.width <= self.width && size.height <= self.height
    func containsSize(size: CGSize) -> Bool {
        return size.width <= width && size.height <= height
    }
}

func - (lhs: CGSize, rhs: CGSize) -> CGSize {
    return CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
}

func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
    return CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
}


func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func / (left: CGPoint, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.x / right, y: left.y / right)
}

class CollectionViewLabelCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!
}

class TestTableView: UITableView {
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        print("TestTableView drawRect")
    }
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        print("TestTableView willMoveToSuperview")
    }
}

class ViewController: UIViewController {
    let ContentOffsetKeyPath = "contentOffset"
    let ContentLeftWidth: CGFloat = 20
    
    var headerCellWidth: CGFloat = 20
    
    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var zoomingView: UIScrollView!
    @IBOutlet weak var contentTableView: TestTableView!
    @IBOutlet weak var gaugeTableView: UITableView!
    @IBOutlet weak var headerCollectionView: UICollectionView!
    @IBOutlet weak var tapView: UIView!

    @IBOutlet weak var baseWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var baseHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var horizontalSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var verticalSpaceConstraint: NSLayoutConstraint!
    
    var contentZoomScale: CGFloat {
        return min(zoomingView.maximumZoomScale, max(zoomingView.minimumZoomScale, zoomingView.zoomScale))
    }
    
    var cellHeight: CGFloat {
        return zoomingView.bounds.height / 10
    }
    
    let aroundCellCount = 10
    
    deinit {
        contentTableView.removeObserver(self, forKeyPath: ContentOffsetKeyPath, context: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        zoomingView.delegate = self
        zoomingView.maximumZoomScale = 1.5
        zoomingView.minimumZoomScale = 0.8
        
        contentTableView.delegate = self
        contentTableView.dataSource = self
        let vertical = (contentTableView.bounds.height - baseView.bounds.height) / 2
        let horizontal = (contentTableView.bounds.width - baseView.bounds.width) / 2
        contentTableView.contentInset = UIEdgeInsets(horizontal: horizontal, vertical: vertical)
        contentTableView.addObserver(self, forKeyPath: ContentOffsetKeyPath, options: .Old, context: nil)
        
        gaugeTableView.delegate = self
        gaugeTableView.dataSource = self
        gaugeTableView.tableFooterView = UIView()
        
        headerCollectionView.dataSource = self
        headerCollectionView.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if UIScreen.mainScreen().bounds.width > UIScreen.mainScreen().bounds.height {
            baseWidthConstraint.constant = 200
            baseHeightConstraint.constant = 100
        } else {
            baseWidthConstraint.constant = 100
            baseHeightConstraint.constant = 200
        }
        
        let horizontal = baseWidthConstraint.constant / 2
        let vertical = baseHeightConstraint.constant / 2
        
        horizontalSpaceConstraint.constant = -horizontal
        verticalSpaceConstraint.constant = -vertical
        
        contentTableView.contentInset = UIEdgeInsets(horizontal: horizontal, vertical: vertical)
        contentTableView.contentOffset = CGPoint(x: -horizontal, y: -vertical)
        
        gaugeTableView.contentInset = UIEdgeInsets(horizontal: 0, vertical: vertical)
        gaugeTableView.contentOffset = CGPoint(x: 0, y: -vertical)
        
        headerCollectionView.contentOffset = CGPoint(x: -horizontal, y: 0)
        headerCollectionView.contentInset = UIEdgeInsets(horizontal: horizontal, vertical: 0)
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let observeView = object as? UIScrollView else {
            return
        }
        
        let zoomedHeight = zoomingView.bounds.height * contentZoomScale
        let yOffset = (zoomedHeight - zoomingView.bounds.height) / 2
        
        let contentOffset = observeView.contentOffset.y * contentZoomScale
        let gaugeContentHeight = cellHeight * 10 * contentZoomScale
        
        let contentInset = (zoomingView.bounds.height - baseView.bounds.height) / 2
        let resultOffset = contentOffset + yOffset
        let offset = floor((resultOffset + contentInset) / gaugeContentHeight)
        gaugeTableView.contentOffset.y = resultOffset - (gaugeContentHeight * offset)
        
        let zoomedWidth = zoomingView.bounds.width * contentZoomScale
        let xOffset = (zoomedWidth - zoomingView.bounds.width) / 2
        headerCollectionView.contentOffset.x = observeView.contentOffset.x * contentZoomScale + xOffset
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension ViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("HeaderCell", forIndexPath: indexPath)
        
        if let labelCell = cell as? CollectionViewLabelCell {
            labelCell.label.text = String(indexPath.item)
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: headerCellWidth * contentZoomScale, height: 20)
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count: Int
        if tableView == contentTableView {
            count = 30
        } else {
            count = 10 + aroundCellCount
        }
        return count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identifier: String
        let row = CGFloat(indexPath.item) / 10
        
        if tableView == contentTableView {
            identifier = "contentCell"
        } else {
            identifier = "gaugeCell"
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath)
        cell.separatorInset = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsets.zeroInsets
        cell.contentView.backgroundColor = UIColor(hue: row - floor(row), saturation: 0.8, brightness: 0.8, alpha: 1)
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let scale: CGFloat
        if tableView == contentTableView {
            scale = 1
        } else {
            scale = contentZoomScale
        }
        return cellHeight * scale
    }
}

extension ViewController: UIScrollViewDelegate {
    func scrollViewDidZoom(scrollView: UIScrollView) {
        let scale = scrollView.zoomScale
        
        let baseSize = baseView.bounds.size
        let outerViewSize = CGSize(width: scrollView.bounds.width, height: scrollView.bounds.height)
        let outerZoomSize = outerViewSize * scale
        
        let xOffset = (outerZoomSize.width - outerViewSize.width) / 2
        let yOffset = (outerZoomSize.height - outerViewSize.height) / 2
        
        scrollView.contentOffset = CGPoint(x: xOffset, y: yOffset)
        
        if scale <= 1 {
            scrollView.contentInset = UIEdgeInsets(horizontal: -xOffset, vertical: -yOffset)
        } else {
            scrollView.contentInset = UIEdgeInsets.zeroInsets
        }
        
        if baseSize.containsSize(outerZoomSize) {
            let offsetSize = baseSize - outerZoomSize
            let horizontal = offsetSize.height / 2 * scale
            let vertical = offsetSize.width / 2 * scale
            contentTableView.contentInset = UIEdgeInsets(horizontal: horizontal, vertical: vertical)
        } else {
            let horizontalOffset = (outerViewSize.width - baseSize.width) / 2
            let verticalOffset = (outerViewSize.height - baseSize.height) / 2
            let horizontalInset = (horizontalOffset + xOffset) / scale
            let verticalInset = (verticalOffset + yOffset) / scale
            contentTableView.contentInset = UIEdgeInsets(horizontal: horizontalInset, vertical: verticalInset)
        }
        
        gaugeTableView.reloadData()
        headerCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return scrollView.subviews.first
    }
}