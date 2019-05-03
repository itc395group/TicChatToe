//
//  TicTacToeTableViewCell.swift
//  TicChatToe
//
//  Created by Hunter Boleman on 5/2/19.
//  Copyright © 2019 Ricky Bernal. All rights reserved.
//

import UIKit
import Parse

class TicTacToeTableViewCell: UITableViewCell {
    
    // Outlets
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var messageLable: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
