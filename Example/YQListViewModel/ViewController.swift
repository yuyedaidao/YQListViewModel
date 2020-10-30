//
//  ViewController.swift
//  YQListViewModel
//
//  Created by wyqpadding@gmail.com on 10/29/2020.
//  Copyright (c) 2020 wyqpadding@gmail.com. All rights reserved.
//

import UIKit
import YQRefresh
import YQListViewModel
import RxDataSources
import RxSwift
import RxCocoa

typealias SectionData = SectionModel<String, Int>

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let viewModel = ListViewModel<SectionData>()
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "\(UITableViewCell.self)")
       
        let header = YQRefreshHeader{[weak self] () in
            self?.viewModel.loadData()
        }
        
        if #available(iOS 11.0, *) {
            let yOffset = UIApplication.shared.statusBarFrame.height + (self.navigationController?.navigationBar.frame.height ?? 0)
            self.tableView.contentInsetAdjustmentBehavior = .never
            header.yOffset = yOffset
            self.tableView.contentInset = UIEdgeInsets(top: yOffset, left: 0, bottom: 0, right: 0)
        }
        
        self.tableView.yq.header = header
        self.tableView.yq.footer = YQRefreshFooter{[weak self] () in
            self?.viewModel.loadData(.more)
        }
        self.tableView.delegate = self
        
        viewModel.data.bind(to: tableView.rx.items(dataSource: dataSource)).disposed(by: disposeBag)
        viewModel.dataFetcher = { (originalData, action, page, callback) -> FetchCancellable in
            switch action {
            case .refresh:
                let item = DispatchWorkItem {
                    let section = SectionData(model: "A", items: (0 ..< page.size).map{$0})
                    callback(.success([section], page.size))
                }
                DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .seconds(2), execute: item)
                return item
            case .more:
                let item = DispatchWorkItem {
                    let items = originalData.last?.items ?? []
                    let oldIndex = items.count
                    let section = SectionData(model: "A", items: items + (oldIndex ..< oldIndex + page.size).map{$0})
                    callback(.success([section], page.size-1))
                }
                DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .seconds(5), execute: item)
                return item
            }
            
        }
        viewModel.dataState.bind(to: Binder(self, binding: { (self, state) in
            switch state {
            case .loading:
                self.tableView.yq.header?.beginRefreshing()
            case .loadingMore:
                self.tableView.yq.footer?.beginRefreshing()
            case .loaded(let error):
                if let error = error {
                    print(error.localizedDescription)
                }
                self.tableView.yq.header?.endRefreshing()
            case .loadedMore(let error):
                if let error = error {
                    print(error.localizedDescription)
                }
                self.tableView.yq.footer?.endRefreshing()
            case .noMore:
                self.tableView.yq.footer?.noMore()
            @unknown default:
                break
            }
        })).disposed(by: disposeBag)
    }

    var dataSource = RxTableViewSectionedReloadDataSource<SectionData> { (dataSource, tableView, indexPath, model) -> UITableViewCell in
        let cell = tableView.dequeueReusableCell(withIdentifier: "\(UITableViewCell.self)", for: indexPath)
        cell.textLabel?.text = "\(model)"
        cell.textLabel?.textColor = UIColor.red
        return cell
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension DispatchWorkItem: FetchCancellable {}

extension ViewController: UITableViewDelegate {}

enum CustomError: Error {
    case normal
}
