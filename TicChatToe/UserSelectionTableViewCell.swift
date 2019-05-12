//
//  UserSelectionTableViewCell.swift
//  TicChatToe
//
//  Created by Hunter Boleman on 5/9/19.
//  Copyright © 2019 Ricky Bernal. All rights reserved.
//

import UIKit

class UserSelectionTableViewCell: UITableViewCell {

    // Outlets
    @IBOutlet weak var usernameLable: UILabel!
    @IBOutlet weak var statusLable: UILabel!
    @IBOutlet weak var userSelectionButtonOutlet: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
