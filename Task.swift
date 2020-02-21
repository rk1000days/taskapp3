//
//  Task.swift
//  taskapp
//
//  Created by Apple on 2020/02/19.
//  Copyright © 2020 kazuhiro.kabashima. All rights reserved.
//

import RealmSwift

class Task: Object {
    // 管理用ID。プライマリーキー
    @objc dynamic var id = 0
    
    //タイトル
    @objc dynamic var title = ""
    
    //内容
    @objc dynamic var contents = ""
    
    //日時
    @objc dynamic var date = Date()
    
    // id をプライマリーキーとして設定
    override static func primaryKey() -> String?{
        return "id"
}
}
