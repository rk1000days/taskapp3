////
////  ViewController.swift
////  taskapp
////
////  Created by Apple on 2020/02/13.
////  Copyright © 2020 kazuhiro.kabashima. All rights reserved.
////
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    let realm = try! Realm()
    
    //全てのタスクを格納する変数
    
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false)
    
    //検索結果タスクを格納する変数
    var searchArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //デリゲート先を自分に設定する。
        searchBar.delegate = self
        
        //何も入力されていなくてもReturnキーを押せるようにする。
        searchBar.enablesReturnKeyAutomatically = false
        
        //プレースホルダの指定
        searchBar.placeholder = "検索カテゴリを入力してください"
        
        tableView.delegate = self
        tableView.dataSource = self
      
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //画面遷移時にデータを渡すメソッド
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        let inputViewController:InputViewController = segue.destination as! InputViewController
        
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            
            inputViewController.task = taskArray[indexPath!.row]
            inputViewController.task = searchArray[indexPath!.row]
            
        } else {
            let task = Task()
            task.date = Date()
            
            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1
            }
            
            inputViewController.task = task
        }
    }
    
    // 入力画面から戻ってきた時に TableView を更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    //データの個数を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchBar.text == "" {
            return taskArray.count
        } else {
            return searchArray.count
        }
    }
    
    //データの中身を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //再利用可能なcellを得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        //Cellに値を設定する
        let task = taskArray[indexPath.row]
        
        //検索結果タスクを定義
        let resultTask = searchArray[indexPath.row]
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let dateString:String = formatter.string(from: task.date)
        let resultDateString: String = formatter.string(from: resultTask.date)
        
        if searchBar.text == "" {
            //検索欄に何も入っていないときはtaskArrayに格納されているタスクのタイトルと日時を表示
            cell.textLabel?.text = task.title
            cell.detailTextLabel?.text = dateString
            
        } else {
            //そうでないときはsearchResultに格納されているタスクのタイトルと日時を表示
            cell.textLabel?.text = resultTask.title
            cell.detailTextLabel?.text = resultDateString
        }
        return cell
        
    }
    
    // MARK: UITableViewDelegateプロトコルのメソッド
    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue",sender: nil)
    }
    
    //セルが削除可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return.delete
    }
    
    //Deleteボタンが押されたときに呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            //削除されたタスクを取得する
            let task = self.taskArray[indexPath.row]
            let resultTask = self.searchArray[indexPath.row]
            
            //ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
            center.removePendingNotificationRequests(withIdentifiers: [String(resultTask.id)])
            
            //データベースから削除する
            try! realm.write {
                self.realm.delete(task)
                self.realm.delete(resultTask)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            //未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/---------------")
                    print(request)
                    print("---------------/")
                }
                
            }
        }
    }
    
    // 検索ボタンが押された時に呼ばれる
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        searchBar.showsCancelButton = true
        
        if (searchBar.text == "") {
            //検索文字列が空の場合はすべてを表示する。
            searchArray = taskArray
        } else {
            // NSPredicateを使って検索条件を指定する
            let predicate = NSPredicate(format: "category = %@", searchBar.text!)
            //上記の条件をもとにsearchResultの中身を絞り込む
            searchArray = realm.objects(Task.self).filter(predicate)
        }
        self.tableView.reloadData()
        
    }
    
    // キャンセルボタンが押された時に呼ばれる
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        self.view.endEditing(true)
        searchBar.text = ""
    }
    
    // テキストフィールド入力開始前に呼ばれる
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true
        return true
    }
}


//import UIKit
//import RealmSwift
//import UserNotifications//追加
//
//
//class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
//
//
//    @IBOutlet weak var tableView: UITableView!
//    @IBOutlet weak var searchBar: UISearchBar!
//
//    // Realmインスタンスを取得する
//    let realm = try! Realm() //追加
//
//    // DB内のタスクが格納されるリスト。
//    //　日付の近い順でソート：昇順
//    //　以降、内容をアップデートするとリスト内は自動的に更新される
//    var taskArray = try! Realm() .objects(Task.self).sorted(byKeyPath: "date", ascending: false)
//
//    //検索結果タスクを格納する変数
//    var searchArray = try! Realm() .objects(Task.self).sorted(byKeyPath: "date", ascending: false)
//
//
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        // Do any additional setup after loading the view.
//
//        searchBar.delegate = self
//
//        searchBar.enablesReturnKeyAutomatically = false
//
//        searchBar.placeholder = "検索カテゴリを入力してください"
//
//
//        tableView.delegate = self
//        tableView.dataSource = self
//    }
//
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//    }
//
//
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let inputViewController:InputViewController = segue.destination as! InputViewController
//
//        if segue.identifier == "cellSegue" {
//
//            let indexPath = self.tableView.indexPathForSelectedRow
//            inputViewController.task = taskArray[indexPath!.row]
//            inputViewController.task = searchArray[indexPath!.row]
//
//        }else{
//            let task = Task()
//            task.date = Date()
//
//            let allTasks = realm.objects(Task.self)
//            if allTasks.count != 0 {
//                task.id = allTasks.max(ofProperty: "id")! + 1
//            }
//            inputViewController.task = task
//        }
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        tableView.reloadData()
//    }
//    //データの数（＝セルの数）を返すメソッド
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if searchBar.text == ""{
//            return taskArray.count
//        }else{
//            return searchArray.count
//        }
//
//        //各セルの内容を返すメソッド
//        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//            //再利用可能なcellを得る
//            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
//
//            // Cellに値を設定する
//            let task = taskArray[indexPath.row]
//
//            let resultTask = searchArray[indexPath.row]
//
//            let formatter = DateFormatter()
//            formatter.dateFormat = "yyyy-MM-dd HH:mm"
//
//            let dateString:String = formatter.string(from: task.date)
//            let resultDateString: String = formatter.string(from: resultTask.date)
//
//            if searchBar.text == ""{
//                cell.textLabel?.text = task.title
//                cell.detailTextLabel?.text = dateString
//            }else{
//                cell.textLabel?.text = resultTask.title
//                cell.detailTextLabel?.text = resultDateString
//            }
//            return cell
//        }
//
//
//        //各セルを選択した時に実行されるメソッド
//        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//            performSegue(withIdentifier: "cellSegue",sender: nil)
//        }
//
//        //セルが削除が可能なことを伝えるメソッド
//        func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
//            return .delete
//        }
//
//        //Deleteボタンが押された時に呼ばれるメソッド
//        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//            // --- ここから ---
//            if editingStyle == .delete {
//                let task = self.taskArray[indexPath.row]
//                let resultTask = self.searchArray[indexPath.row]
//
//                let center = UNUserNotificationCenter.current()
//                center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
//                center.removePendingNotificationRequests(withIdentifiers: [String(resultTask.id)])
//
//                try! realm.write {
//                    self.realm.delete(task)
//                    self.realm.delete(resultTask)
//                    tableView.deleteRows(at: [indexPath], with: .fade)
//                }
//                //未通知のローカル通知一覧をログ出力
//                center.getPendingNotificationRequests{ (requests: [UNNotificationRequest]) in
//                    for request in requests {
//                        print("/-------")
//                        print(request)
//                        print("-------/")
//                    }
//                }
//            }
//            // --- ここまで追加 ---
//        }
//
//
//        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//            self.view.endEditing(true)
//            searchBar.showsCancelButton = true
//
//            if searchBar.text == ""{
//                searchArray = taskArray
//            }else{
//                let predicte = NSPredicate(format: "category = &@", searchBar.text!)
//                searchArray = realm.objects(Task.self).filter(predicte)
//            }
//            self.tableView.reloadData()
//
//        }
//
//        func searchBarCancelButtonClicked(_ searchBar: UISearchBar){
//            searchBar.showsCancelButton = false
//            self.view.endEditing(true)
//            searchBar.text = ""
//        }
//
//
//        func seachBarShouldBeginEditing(_ seachBar: UISearchBar) -> Bool{
//            seachBar.showsCancelButton = true
//            return true
//        }
//
//
//    }
//
//}
