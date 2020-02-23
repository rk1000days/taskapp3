//
//  ViewController.swift
//  taskapp
//
//  Created by Apple on 2020/02/13.
//  Copyright © 2020 kazuhiro.kabashima. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications//追加


class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    // Realmインスタンスを取得する
    let realm = try! Realm() //追加
    
    // DB内のタスクが格納されるリスト。
    //　日付の近い順でソート：昇順
    //　以降、内容をアップデートするとリスト内は自動的に更新される
    
    var taskArray = try! Realm() .objects(Task.self).sorted(byKeyPath: "date", ascending: false)
    
    var searchArray = try! Realm() .objects(Task.self).sorted(byKeyPath: "date", ascending: false)
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        searchBar.delegate = self
        
        searchBar.enablesReturnKeyAutomatically = false
        
        searchBar.placeholder = "検索カテゴリを入力してください"
        
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    //データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchBar.text == ""{
        return taskArray.count
        }else{
            return searchArray.count
        }
    
    //各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //再利用可能なcellを得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // Cellに値を設定する
        let task = taskArray[indexPath.row]
        
        let resultTask = searchArray[indexPath.row]
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let dateString:String = formatter.string(from: task.date)
        let resultDateString: String = formatter.string(from: resultTask.date)

        if searchBar.text == ""{
            cell.textLabel?.text = task.title
            cell.detailTextLabel?.text = dateString
        }else{
            cell.textLabel?.text = resultTask.title
            cell.detailTextLabel?.text = resultDateString
        }
        return cell
    }
    
    //各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue",sender: nil)
    }
    
    //セルが削除が可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    //Deleteボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // --- ここから ---
        if editingStyle == .delete {
            let task = self.taskArray[indexPath.row]
            let resultTask = self.searchArray[indexPath.row]
            
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
            
            try! realm.write {
                self.realm.delete(task)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            //未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests{ (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/-------")
                    print(request)
                    print("-------/")
                }
            }
        }
        // --- ここまで追加 ---
    }
   
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let inputViewController:InputViewController = segue.destination as! InputViewController
        
        if segue.identifier == "cellSegue" {
            
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
            inputViewController.task = searchArray[indexPath!.row]
            
        }else{
            let task = Task()
            task.date = Date()
            
            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1
            }
            inputViewController.task = task
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
   
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            self.view.endEditing(true)
            searchBar.showsCancelButton = true
            
            if searchBar.text == ""{
                searchArray = taskArray
            }else{
                let predicte = NSPredicate(format: "category = &@", searchBar.text!)
                searchArray = realm.objects(Task.self).filter(predicte)
            }
            self.tableView.reloadData()
        }
        
        func searchBarCancelButtonClicked(_ searchBar: UISearchBar){
            searchBar.showsCancelButton = false
            self.view.endEditing(true)
            searchBar.text = ""
        }
        
        func seachBarShouldBeginEditing(_ seachBar: UISearchBar) -> Bool{
            seachBar.showsCancelButton = true
            return true
        }
        
}






