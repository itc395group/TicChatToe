//
//  UserSelectionTableViewController.swift
//  TicChatToe
//
//  Created by Hunter Boleman on 4/27/19.
//  Copyright © 2019 Ricky Bernal. All rights reserved.
//

import UIKit
import Parse

class UserSelectionTableViewController: UITableViewController {
    
    // Class Variables
    let expireTime = 10.0
    var onlineUsers: [PFObject] = [];
    var queryLimit = 5

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    //-------------------- Utilities --------------------//
    
    // Finds if object is expired or not
    func isExpired(obj: PFObject) -> Bool {
        
        if ((obj["updatedAt"]) == nil){
            print("EXPIRED")
            return true;
        }
        
        let storedTime = obj["updatedAt"] as! Date;
        
        if (storedTime >= Date().addingTimeInterval(expireTime)){
            print("EXPIRED")
            return true
        }
        else {
            print("not-expired")
            return false
        }
    }
    
    func getOnlineUserList(){
        print("Get Parse Data")
        
        let query = PFQuery(className:"Users")
        query.limit = queryLimit;
        query.includeKey("user")
        query.whereKey("updatedAt", greaterThan: Date().addingTimeInterval(expireTime))
        query.order(byDescending: "updatedAt")
        
        query.findObjectsInBackground { (messages, error) in
            if let error = error {
                // Log details of the failure
                print(error.localizedDescription)
            } else if let message = messages {
                // The find succeeded.
                self.onlineUsers = message
                print("Successfully retrieved \(message.count) posts.")
            }
            print ("reload tableView")
            //self.tableView.reloadData();
        }
    }
    
    
    @IBAction func testUserBtn(_ sender: Any) {
        getOnlineUserList()
        
        for index in 0..<onlineUsers.count {
            let singleUser = self.onlineUsers[index];
            let usr = singleUser["user"] as! PFUser
            if (isExpired(obj: singleUser) == true) {
                print("expired user: \(usr.username ?? "")")
                
            }
            else{
                print("online user: \(usr.username ?? "")")
            }
        }
        
    }
    
    @IBAction func testSetOnlineBtn(_ sender: Any) {
        // This snippit will reset the "dead man's switch"
        var objID = "";
        let countOfMessages = self.onlineUsers.count;
        print()
        for index in 0..<countOfMessages {
            // gets a single message
            let singleUser = self.onlineUsers[index];
            let usr = (singleUser["user"] as? PFUser)
            let id = (singleUser["objectId"])
            let upd = (singleUser["updatedAt"] as! Date)
            
            if(usr == PFUser.current()){
                objID = id as! String;
                print("Date Found Before Update: \(upd)")
            }
        }
        
        let query = PFQuery(className:"Users")
        query.limit = queryLimit;
        query.includeKey("user")
        query.whereKey("updatedAt", greaterThan: Date().addingTimeInterval(expireTime))
        query.order(byDescending: "updatedAt")
        
        query.getObjectInBackground(withId: objID) { (obj, error) in
            if error != nil {
                print(error as Any)
            }
            else{
                // Updates UpdatedAt
                obj?.saveInBackground()
            }
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
