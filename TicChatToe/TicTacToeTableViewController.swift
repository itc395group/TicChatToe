//
//  TicTacToeTableViewController.swift
//  TicChatToe
//
//  Created by Hunter Boleman on 5/2/19.
//  Copyright © 2019 Ricky Bernal. All rights reserved.
//

import UIKit
import Parse

class TicTacToeViewController: UIViewController, UITableViewDataSource {
    
    // Make UserDefautls Accessable
    //let defaults = UserDefaults.standard
    
    // Class Variables
    var connectedUser: String = "" 
    let expireTime = 30.0;
    var currentTurnNum = 0;
    let dataExpireTime = 10.0;
    var tttRunTimer: Bool = true;
    var tttTimerCount: Int = 0;
    var tttTimerMax: Int = 3;
    var playersPiece: String = ""
    var didWin: Bool = false
    var whoWon: String = ""
    
    // Master Message Object
    var chatMessages: [PFObject] = [];
    var tttData: [PFObject] = [];
    
    //Outlets
    @IBOutlet weak var chatMessageField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    //Outlets for tic tac toe buttons
    @IBOutlet weak var row1col1: UIButton!
    @IBOutlet weak var row1col2: UIButton!
    @IBOutlet weak var row1col3: UIButton!
    @IBOutlet weak var row2col1: UIButton!
    @IBOutlet weak var row2col2: UIButton!
    @IBOutlet weak var row2col3: UIButton!
    @IBOutlet weak var row3col1: UIButton!
    @IBOutlet weak var row3col2: UIButton!
    @IBOutlet weak var row3col3: UIButton!
    
    
    @IBOutlet weak var navBarOutlet: UINavigationItem!
    
    //Color Refrence
    let myRed = UIColor(red:0.89, green:0.44, blue:0.31, alpha:1.0);
    let myBlue = UIColor(red:0.19, green:0.62, blue:0.79, alpha:1.0);
    let myGreen = UIColor(red:0.56, green:0.81, blue:0.48, alpha:1.0);
    
    
    /*@IBAction func ticTacToeGridAction(_ sender: Any) {
     
     
     if (currentTurnNum/2 == 0){
     sendValidMove(symbol: "X", row: <#T##Int#>, col: <#T##Int#>, turnNum: currentTurnNum)
     } else{
     sendValidMove(symbol: "O", row: <#T##Int#>, col: <#T##Int#>, turnNum: currentTurnNum)
     }
     currentTurnNum = currentTurnNum + 1
     }
     */
    
    
    override func viewWillDisappear(_ animated: Bool) {
        
        //        if (defaults.string(forKey: "nil_test") == nil){
        //            defaults.set(true, forKey: "reset");
        //            defaults.set("TEST", forKey: "nil_test");
        //            defaults.synchronize();
        //        }
        //        defaults.set(true, forKey: "reset");
        //        defaults.synchronize();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("TESTING: \(connectedUser)")
        
        EarlyGarbageCollection()
        
        updateTurnTitle()
        
        if (isMyTurn() == true){
            navBarOutlet.title = ("[\(playersPiece)] Your Turn")
        }
        else {
            navBarOutlet.title = ("[\(playersPiece)] Wait...")
        }
        
        // Needed for the UITableView
        tableView.dataSource = self as UITableViewDataSource
        // Auto size row height based on cell autolayout constraints
        tableView.rowHeight = UITableView.automaticDimension
        // Provide an estimated row height. Used for calculating scroll indicator
        tableView.estimatedRowHeight = 50
        // Sets getChatMessage to retrieve messages every 5 seconds
        Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.getChatMessages), userInfo: nil, repeats: true)
        
        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.timedFunc), userInfo: nil, repeats: true)
        // runs getChatMessages for the first time
        getChatMessages();
        print ("reload tableView")
        self.tableView.reloadData();
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
      //init toolbar
    
}
    //-------------------- Main Timer Function --------------------//
    
    // The logic that will run on a timer
    @objc func timedFunc() {
        // Run when timer is "active"
        if (tttRunTimer == true){
            print("in active timed func")
            
            // Refresh player list at begining of count
            if (tttTimerCount <= 0){
                getTicTacToeData()
            }
            
            // Listen for data at end of count
            if (tttTimerCount >= tttTimerMax){
                listenForValidMove()
                checkIfWin()
                updateTurnTitle()
                garbageCollection()
            }
            
            // Used to create actions on a delay
            if (tttTimerCount >= tttTimerMax){tttTimerCount = 0}
            tttTimerCount = tttTimerCount + 1;
        }
    }
    
    //-------------------- Chat Functionality --------------------//
    
    @IBAction func messageFieldPrimaryAction(_ sender: Any) {
        chatMessageField.resignFirstResponder()
    }
    
    // Gets Chat Messages
    @objc func getChatMessages(){
        let query = PFQuery(className:"Messages")
        query.addDescendingOrder("createdAt")
        query.limit = 5
        query.includeKey("user")
        
        query.findObjectsInBackground { (messages, error) in
            if let error = error {
                // Log details of the failure
                print(error.localizedDescription)
            } else if let messages = messages {
                // The find succeeded.
                self.chatMessages = messages
                print("Successfully retrieved \(messages.count) posts.")
            }
        }
        print ("reload tableView")
        self.tableView.reloadData();
    }
    
    // Sends The User's Message
    @IBAction func doSendMessage(_ sender: Any) {
        let chatMessage = PFObject(className: "Messages");
        chatMessage["text"] = chatMessageField.text!
        chatMessage["user"] = PFUser.current();
        chatMessage.saveInBackground { (success, error) in
            if success {
                print("The message was saved!")
                self.chatMessageField.text = "";
            } else if let error = error {
                print("Problem saving message: \(error.localizedDescription)")
            }
        }
    }
    
    //-------------------- Table View Related --------------------//
    
    // Sets Table Rows
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        for index in 0..<chatMessages.count {
            isExpired(obj: chatMessages[index])
        }
        return chatMessages.count;
    }
    
    // Sets Table Cell Contents
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Reusable Cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicTacToeTableViewCell") as! TicTacToeTableViewCell;
        // gets a single message
        let chatMessage = chatMessages[indexPath.row];
        // Set text
        cell.messageLable.text = chatMessage["text"] as? String;
        //Set username
        if let user = chatMessage["user"] as? PFUser {
            // User found! update username label with username
            cell.usernameLabel.text = user.username;
        } else {
            // No user found, set default username
            cell.usernameLabel.text = "🤖"
        }
        return cell;
    }
    
    //-------------------- Utilities --------------------//
    
    func garbageCollection(){
        print("GARBAGE COLLECTING...")
        for index in 0..<tttData.count{
            isExpired(obj: tttData[index])
        }
        for index in 0..<chatMessages.count{
            isExpired(obj: chatMessages[index])
        }
        getChatMessages()
        getTicTacToeData()
        print("END GARBAGE COLLECTING")
    }
    
    func EarlyGarbageCollection(){
        print("EARLY GARBAGE DUMP...")
        for index in 0..<tttData.count{
            let singleUser = self.tttData[index];
            let usr = (singleUser["user"] as! PFUser).username
            if(usr == PFUser.current()?.username || usr == connectedUser){
                garbageObj(obj: tttData[index])
            }
        }
        for index in 0..<chatMessages.count{
            let singleUser = self.chatMessages[index];
            let usr = (singleUser["user"] as! PFUser).username
            if(usr == PFUser.current()?.username || usr == connectedUser){
                garbageObj(obj: chatMessages[index])
            }
        }
        getChatMessages()
        getTicTacToeData()
        print("END EARLY GARBAGE DUMP")
    }
    
    func updateTurnTitle(){
        if (isMyTurn() == true && didWin == false){
            navBarOutlet.title = ("[\(playersPiece)] Your Turn")
        }
        else if (isMyTurn() == false && didWin == false) {
            navBarOutlet.title = ("[\(playersPiece)] Wait...")
        }
        else if (isMyTurn() == false && didWin == true){
            if (whoWon == playersPiece){
                navBarOutlet.title = ("[\(playersPiece)] Game! You Won!")
            }
            else if (whoWon == "-"){
                navBarOutlet.title = ("[\(playersPiece)] Game! You Draw!")
            }
            else {
                navBarOutlet.title = ("[\(playersPiece)] Game! You Lost!")
            }
        }
    }
    
    // Finds if object is expired or not, and if it is it will call the garbage collector.
    func isExpired(obj: PFObject) -> Bool {
        if ((obj.createdAt) == nil){
            print("EXPIRED")
            garbageObj(obj: obj)
            return true;
        }
        
        
        let storedTime = obj.createdAt as! Date;
        let expTime = storedTime.addingTimeInterval(expireTime);
        let nowTime = Date();
        
        if (expTime < nowTime){
            garbageObj(obj: obj)
            return true
        }
        else {
            return false
        }
    }
    
    // Finds if object is expired or not, and if it is it will call the garbage collector.
    func isDataExpired(obj: PFObject) -> Bool {
        if ((obj.createdAt) == nil){
            print("EXPIRED")
            garbageObj(obj: obj)
            return true;
        }
        
        
        let storedTime = obj.createdAt as! Date;
        let expTime = storedTime.addingTimeInterval(dataExpireTime);
        let nowTime = Date();
        
        if (expTime < nowTime){
            garbageObj(obj: obj)
            return true
        }
        else {
            return false
        }
    }
    
    // Used for populating the tableview without disrupting it's own process (aka, it doesn't remove anything during the check)
    func canDisplay(obj: PFObject) -> Bool {
        if ((obj.createdAt) == nil){
            print("EXPIRED")
            return false;
        }
        
        let storedTime = obj.createdAt as! Date;
        let expTime = storedTime.addingTimeInterval(expireTime);
        let nowTime = Date();
        
        if (expTime < nowTime){
            return false
        }
        else {
            return true
        }
    }
    
    // Removed a specified object
    func garbageObj(obj: PFObject){
        obj.deleteInBackground(block: { (sucess, error) in
            if (sucess == true){
                print("Delete: TRUE")
                //self.getOnlineUserList()
            }
            else {
                print("Delete: FALSE")
            }
        })
    }
    
    //-------------------- Tic Tac Toe Data Handling --------------------//
    
    func sendValidMove(symbol: String, row: Int, col: Int, turnNum: Int){
        updateBoard(row: row, col: col, piece: symbol)
        
        let data = PFObject(className: "TicTacToe");
        data["user"] = PFUser.current();
        data["symbol"] = symbol
        data["row"] = row
        data["col"] = col
        data["turn"] = turnNum
        data.saveInBackground { (success, error) in
            if success {
                print("The TicTacToe data was saved!")
                self.chatMessageField.text = "";
            } else if let error = error {
                print("Problem saving message: \(error.localizedDescription)")
            }
        }
    }
    
    func listenForValidMove(){
        // [row][col]
        //   1 2 3
        // 1 X X X
        // 2 X X X
        // 3 X X X
        
        for index in 0..<tttData.count {
            let singleData = tttData[index];
            let user = singleData["user"] as! PFUser
            let symbol = singleData["symbol"] as! String
            let row = singleData["row"] as! Int
            let col = singleData["col"] as! Int
            let turn = singleData["turn"] as! Int
            
            if (user.username == connectedUser && turn > currentTurnNum && isExpired(obj: singleData) == false){
                // Send move to Tic Tac Toe Front End Logic
                processingReceivedMove(Symbol: symbol, row: row, col: col)
                // processRecievedMove(symbol, row, col, turn)
                garbageObj(obj: singleData)
            }
        }
    }
    
    func getTicTacToeData(){
        let query = PFQuery(className:"TicTacToe")
        query.addDescendingOrder("createdAt")
        query.limit = 20
        query.includeKey("user")
        
        query.findObjectsInBackground { (messages, error) in
            if let error = error {
                // Log details of the failure
                print(error.localizedDescription)
            } else if let messages = messages {
                // The find succeeded.
                self.tttData = messages
                print("Successfully retrieved TicTacToe \(messages.count) posts.")
            }
        }
    }
    
    // Tic Tac Toe Front End Logic
    
    func checkIfWin() -> Bool {
        print("in checkIfWin")
        //check if there are 3 in a row on the board
        
            //row 1
        if ( (row1col1.currentTitle == "O" && row1col2.currentTitle == "O" && row1col3.currentTitle == "O") ){
            whoWon = "O"
            return true
        }
            //row 2
        else if (  (row2col1.currentTitle == "O" && row2col2.currentTitle == "O" && row2col3.currentTitle == "O" )){
            whoWon = "O"
            return true
        }
            //row 3
        else if ( (row3col1.currentTitle == "O" && row3col2.currentTitle == "O" && row3col3.currentTitle == "O" )){
            whoWon = "O"
            return true
        }
            //column 1
        else if (  (row1col1.currentTitle == "O" && row2col1.currentTitle == "O" && row3col1.currentTitle == "O" )){
            whoWon = "O"
            return true
        }
            //column 2
        else if ( (row1col2.currentTitle == "O" && row2col2.currentTitle == "O" && row3col2.currentTitle == "O")){
            whoWon = "O"
            return true
        }
            //column 3
        else if ( (row1col3.currentTitle == "O" && row2col3.currentTitle == "O" && row3col3.currentTitle == "O")){
            whoWon = "O"
            return true
        }
            //diagonal 1
        else if ( (row1col1.currentTitle == "O" && row2col2.currentTitle == "O" && row3col3.currentTitle == "O")){
            whoWon = "O"
            return true
        }
            //diagonal 2
        else if ( (row1col3.currentTitle == "O" && row2col2.currentTitle == "O" && row3col1.currentTitle == "O")){
            whoWon = "O"
            return true
        }
            //row 1
        else if ( (row1col1.currentTitle == "X" && row1col2.currentTitle == "X" && row1col3.currentTitle == "X")  ){
            whoWon = "X"
            return true
        }
            //row 2
        else if ( (row2col1.currentTitle == "X" && row2col2.currentTitle == "X" && row2col3.currentTitle == "X" ) ){
            whoWon = "X"
            return true
        }
            //row 3
        else if (( row3col1.currentTitle == "X" && row3col2.currentTitle == "X" && row3col3.currentTitle == "X") ){
            whoWon = "X"
            return true
        }
            //column 1
        else if ( (row1col1.currentTitle == "X" && row2col1.currentTitle == "X" && row3col1.currentTitle == "X") ){
            whoWon = "X"
            return true
        }
            //column 2
        else if (( row1col2.currentTitle == "X" && row2col2.currentTitle == "X" && row3col2.currentTitle == "X" ) ){
            whoWon = "X"
            return true
        }
            //column 3
        else if (( row1col3.currentTitle == "X" && row2col3.currentTitle == "X" && row3col3.currentTitle == "X" ) ){
            whoWon = "X"
            return true
        }
            //diagonal 1
        else if (( row1col1.currentTitle == "X" && row2col2.currentTitle == "X" && row3col3.currentTitle == "X") ){
            whoWon = "X"
            return true
        }
            //diagonal 2
        else if (( row1col3.currentTitle == "X" && row2col2.currentTitle == "X" && row3col1.currentTitle == "X") ){
            whoWon = "X"
            return true
        }
        // Draw
        else if (
            (row1col1.currentTitle == "X" || row1col1.currentTitle == "O") &&
            (row1col2.currentTitle == "X" || row1col2.currentTitle == "O") &&
            (row1col3.currentTitle == "X" || row1col3.currentTitle == "O") &&
        
            (row2col1.currentTitle == "X" || row2col1.currentTitle == "O") &&
            (row2col2.currentTitle == "X" || row2col2.currentTitle == "O") &&
            (row2col3.currentTitle == "X" || row2col3.currentTitle == "O") &&
            
            (row3col1.currentTitle == "X" || row3col1.currentTitle == "O") &&
            (row3col2.currentTitle == "X" || row3col2.currentTitle == "O") &&
            (row3col3.currentTitle == "X" || row3col3.currentTitle == "O")
            ){
            whoWon = "-"
            return true
        }
        return false
    }
    
    func processingReceivedMove(Symbol: String, row: Int, col: Int){
        if (row == 1 && col == 1){
            updateBoard(row: row, col: col, piece: Symbol)
        }else if (row == 1 && col == 2){
            updateBoard(row: row, col: col, piece: Symbol)
        }else if (row == 1 && col == 3){
            updateBoard(row: row, col: col, piece: Symbol)
        }else if (row == 2 && col == 1){
            updateBoard(row: row, col: col, piece: Symbol)
        }else if (row == 2 && col == 2){
            updateBoard(row: row, col: col, piece: Symbol)
        }else if (row == 2 && col == 3){
            updateBoard(row: row, col: col, piece: Symbol)
        }else if (row == 3 && col == 1){
            updateBoard(row: row, col: col, piece: Symbol)
        }else if (row == 3 && col == 2){
            updateBoard(row: row, col: col, piece: Symbol)
        }else if (row == 3 && col == 3){
            updateBoard(row: row, col: col, piece: Symbol)
        }
        if (checkIfWin() == true){
            print("X Wins")
        }
        if (checkIfWin() == true){
            print("O wins")
        }
        currentTurnNum = currentTurnNum + 1
    }
    
    
    //tictactoe button actions
    
    func updateBoard(row: Int, col: Int, piece: String){
        updateTurnTitle()
        var color = myRed
        
        if (piece == "O"){
            color = myGreen
        }
        else if (piece == "X"){
            color = myRed
        }
        
        if (row == 1){
            if (col == 1){
                // Row 1 Col 1
                row1col1.setTitle(piece, for: UIControl.State.init())
                row1col1.setTitleColor(color, for: UIControl.State.init())
                row1col1.backgroundColor = UIColor.clear
            }
            if (col == 2){
                // Row 1 Col 2
                row1col2.setTitle(piece, for: UIControl.State.init())
                row1col2.setTitleColor(color, for: UIControl.State.init())
                row1col2.backgroundColor = UIColor.clear
            }
            if (col == 3){
                // Row 1 Col 3
                row1col3.setTitle(piece, for: UIControl.State.init())
                row1col3.setTitleColor(color, for: UIControl.State.init())
                row1col3.backgroundColor = UIColor.clear
            }
        }
        
        else if (row == 2){
            if (col == 1){
                // Row 2 Col 1
                row2col1.setTitle(piece, for: UIControl.State.init())
                row2col1.setTitleColor(color, for: UIControl.State.init())
                row2col1.backgroundColor = UIColor.clear
            }
            if (col == 2){
                // Row 2 Col 2
                row2col2.setTitle(piece, for: UIControl.State.init())
                row2col2.setTitleColor(color, for: UIControl.State.init())
                row2col2.backgroundColor = UIColor.clear
            }
            if (col == 3){
                // Row 2 Col 3
                row2col3.setTitle(piece, for: UIControl.State.init())
                row2col3.setTitleColor(color, for: UIControl.State.init())
                row2col3.backgroundColor = UIColor.clear
            }
        }
        
        else if (row == 3){
            if (col == 1){
                // Row 3 Col 1
                row3col1.setTitle(piece, for: UIControl.State.init())
                row3col1.setTitleColor(color, for: UIControl.State.init())
                row3col1.backgroundColor = UIColor.clear
            }
            if (col == 2){
                // Row 3 Col 2
                row3col2.setTitle(piece, for: UIControl.State.init())
                row3col2.setTitleColor(color, for: UIControl.State.init())
                row3col2.backgroundColor = UIColor.clear
            }
            if (col == 3){
                // Row 3 Col 3
                row3col3.setTitle(piece, for: UIControl.State.init())
                row3col3.setTitleColor(color, for: UIControl.State.init())
                row3col3.backgroundColor = UIColor.clear
            }
        }
    }
    
    func isMyTurn() -> Bool {
        if (checkIfWin() == false){
            if (playersPiece == "X"){
                if ((currentTurnNum % 2) == 0){
                    (print("IS TURN"))
                    return true
                }
                else{
                    (print("NOT TURN"))
                    return false
                }
            }
            else if (playersPiece == "O"){
                if ((currentTurnNum % 2) == 0){
                    (print("NOT TURN"))
                    return false
                }
                else{
                    (print("IS TURN"))
                    return true
                }
            }
        }
        else {
            didWin = true
            return false
        }
        return false
    }
    
    
    @IBAction func row1col1(_ sender: Any) {
        //check to make sure square is empty and game is active
        if (row1col1.currentTitle != "X" && row1col1.currentTitle != "O" && isMyTurn() == true){
                sendValidMove(symbol: playersPiece, row: 1, col: 1, turnNum: currentTurnNum + 1)
            currentTurnNum = currentTurnNum + 1
        }
        else{
            print("invalid move")
            updateTurnTitle()
        }
    }
    
    
    @IBAction func row1col2(_ sender: Any) {
        //check to make sure square is empty and game is active
        if (row1col2.currentTitle != "X" && row1col2.currentTitle != "O" && isMyTurn() == true){
            sendValidMove(symbol: playersPiece, row: 1, col: 2, turnNum: currentTurnNum + 1)
            currentTurnNum = currentTurnNum + 1
        }
        else{
            print("invalid move")
            updateTurnTitle()
        }
    }
    @IBAction func row1col3(_ sender: Any) {
        //check to make sure square is empty and game is active
        if (row1col3.currentTitle != "X" && row1col3.currentTitle != "O" && isMyTurn() == true){
            sendValidMove(symbol: playersPiece, row: 1, col: 3, turnNum: currentTurnNum + 1)
            currentTurnNum = currentTurnNum + 1
        }
        else{
            print("invalid move")
            updateTurnTitle()
        }
    }
    @IBAction func row2col1(_ sender: Any) {
        //check to make sure square is empty and game is active
        if (row2col1.currentTitle != "X" && row2col1.currentTitle != "O" && isMyTurn() == true){
            sendValidMove(symbol: playersPiece, row: 2, col: 1, turnNum: currentTurnNum + 1)
            currentTurnNum = currentTurnNum + 1
        }
        else{
            print("invalid move")
            updateTurnTitle()
        }
    }
    @IBAction func row2col2(_ sender: Any) {
        //check to make sure square is empty and game is active
        if (row2col2.currentTitle != "X" && row2col2.currentTitle != "O" && isMyTurn() == true){
            sendValidMove(symbol: playersPiece, row: 2, col: 2, turnNum: currentTurnNum + 1)
            currentTurnNum = currentTurnNum + 1
        }
        else{
            print("invalid move")
            updateTurnTitle()
        }
    }
    @IBAction func row2col3(_ sender: Any) {
        //check to make sure square is empty and game is active
        if (row2col3.currentTitle != "X" && row2col3.currentTitle != "O" && isMyTurn() == true){
            sendValidMove(symbol: playersPiece, row: 2, col: 3, turnNum: currentTurnNum + 1)
            currentTurnNum = currentTurnNum + 1
        }
        else{
            print("invalid move")
            updateTurnTitle()
        }
    }
    @IBAction func row3col1(_ sender: Any) {
        //check to make sure square is empty and game is active
        if (row3col1.currentTitle != "X" && row3col1.currentTitle != "O" && isMyTurn() == true){
            sendValidMove(symbol: playersPiece, row: 3, col: 1, turnNum: currentTurnNum + 1)
            currentTurnNum = currentTurnNum + 1
        }
        else{
            print("invalid move")
            updateTurnTitle()
        }
    }
    @IBAction func row3col2(_ sender: Any) {
        //check to make sure square is empty and game is active
        if (row3col2.currentTitle != "X" && row3col2.currentTitle != "O" && isMyTurn() == true){
            sendValidMove(symbol: playersPiece, row: 3, col: 2, turnNum: currentTurnNum + 1)
            currentTurnNum = currentTurnNum + 1
        }
        else{
            print("invalid move")
            updateTurnTitle()
        }
    }
    @IBAction func row3col3(_ sender: Any) {
        //check to make sure square is empty and game is active
        if (row3col3.currentTitle != "X" && row3col3.currentTitle != "O" && isMyTurn() == true){
            sendValidMove(symbol: playersPiece, row: 3, col: 3, turnNum: currentTurnNum + 1)
            currentTurnNum = currentTurnNum + 1
        }
        else{
            print("invalid move")
            updateTurnTitle()
        }
    }
    
    // MARK: - Table view data source
    
    
    
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
     }*/
}
