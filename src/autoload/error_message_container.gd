extends Node

const DATABASE_STRING : String = "Database"
const LIST_STRING : String = "List"
const INVENTORY_STRING : String = "Inventory"
const MONEY_STRING : String = "Money"

const INVALID_ID : String = "%s ERROR, item with ID: %s does not exist in %s"
const WITHDRAW_NO_STOCK : String = "%s ERROR, withdraw failed. Not enough stock for: %s"
const WITHDRAW_INVALID_AMOUNT : String = "%s ERROR, withraw failed. Invalid withraw amount: %s"
const RESOURCE_ERROR : String = "Resource ERROR, currently have %s, and need %s %s"
