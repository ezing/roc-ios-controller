//
//  ConversationsViewController.swift
//  ROCController
//
//  Created by Maximilian Alexander on 3/17/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import ROCController
import RealmSwift

import Fakery // import just for demo purposes begin here

class MinimalConversationsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    lazy var tableView: UITableView = {
        let t = UITableView()
        t.delegate = self
        t.dataSource = self
        t.translatesAutoresizingMaskIntoConstraints = false
        t.register(MinimalConversationTableViewCell.self, forCellReuseIdentifier: MinimalConversationTableViewCell.REUSE_ID)
        return t
    }()
    
    var token: NotificationToken?
    let realm: Realm
    let conversations: Results<MinimalConversation>
    
    init(){
        self.realm = try! Realm()
        self.conversations = self.realm.objects(MinimalConversation.self).sorted(byKeyPath: "timestamp", ascending: false)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Conversations"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        view.addSubview(tableView)
        let views: [String: UIView] = [
            "tableView": tableView
        ]
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[tableView]-0-|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[tableView]-0-|", options: [], metrics: nil, views: views))
        
        //if no conversations are present lets just bootstrap 20 converations some for fun.
        if self.conversations.count == 0 {
            let faker = Faker()
            var conversationsToAdd = [MinimalConversation]()
            for i in 1...20 {
                let conversation = MinimalConversation()
                conversation.conversationId = "\(i)"
                conversation.displayName = "\(faker.name.firstName()) \(faker.name.lastName())"
                
                let imageUrl = faker.internet.image(width: 160, height: 160)
                let imageUrlWithRedundantQueryString = "\(imageUrl)?v=\(i)"
                
                conversation.imageUrl = imageUrlWithRedundantQueryString
                conversation.summary = faker.lorem.sentence()
                conversationsToAdd.append(conversation)
            }
            try! realm.write {
                realm.add(conversationsToAdd, update: true)
            }
        }
        
        token = self.conversations.addNotificationBlock({ [weak self] (changes) in
            guard let tableView = self?.tableView else { return }
            switch changes {
            case .initial:
                tableView.reloadData()
                break
            case .update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the UITableView
                tableView.beginUpdates()
                tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
                                     with: .automatic)
                tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}),
                                     with: .automatic)
                tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
                                     with: .automatic)
                tableView.endUpdates()
                break
            case .error(let error):
                fatalError("\(error)")
                break
            }
        })
        
    }
    
    deinit {
        token?.stop()
    }
    
    //UITableViewDataSource and UITableViewDelegate Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return MinimalConversationTableViewCell.HEIGHT
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MinimalConversationTableViewCell.REUSE_ID, for: indexPath) as! MinimalConversationTableViewCell
        let conversation = conversations[indexPath.row]
        cell.setupWithConversation(conversation: conversation)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let conversation = conversations[indexPath.row]
        let chatViewController = MinimalChatController(conversation: conversation)
        navigationController?.pushViewController(chatViewController, animated: true)
    }
    
}
