pageextension 80021 "PC Accountant Role Center" extends "9027"
{
    actions
    {
        // Adding a new action group 'MyNewActionGroup' in the 'Creation' area
        addlast(Analysis)
        {
            group("Sales Analysis")
            {
                action("Sales Analysis Views")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Sales Analysis Views';
                    Image = AnalysisView;
                    RunObject = Page "Analysis View List Sales";
                    ToolTip = 'Analyze Sales by their dimensions using analysis views that you have set up.';
                }
                action("Sales Analysis Reports")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Sales Analysis Reports';
                    Image = AnalysisView;
                    RunObject = Page "Analysis Report Sale";
                    ToolTip = 'Analyze Sales by their dimensions using analysis views that you have set up.';
                }
                action("Sales Analysis by Dimensions")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Sales Analysis by Dimensions';
                    Image = AnalysisView;
                    RunObject = Page "Sales Analysis by Dimensions";
                    ToolTip = 'Analyze Sales by their dimensions using analysis views that you have set up.';
                }
            }
            group("Purchase Analysis")
            {
                action("Item Analysis Views")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Item Analysis Views';
                    Image = AnalysisView;
                    RunObject = Page "Item Analysis View List";
                    ToolTip = 'Analyze Purchases by their dimensions using analysis views that you have set up.';
                }
                action("Purchase Analysis Reports")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Purchase Analysis Reports';
                    Image = AnalysisView;
                    RunObject = Page "Analysis Report Purchase";
                    ToolTip = 'Analyze Purchases by their dimensions using analysis views that you have set up.';
                }
                action("Purchase Analysis by Dimensions")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Purchase Analysis by Dimensions';
                    Image = AnalysisView;
                    RunObject = Page "7157";
                    ToolTip = 'Analyze Purchases by their dimensions using analysis views that you have set up.';
                }
            }
        }
        addafter(VendorsBalance)
        {
            action("Purchase Blanket Order")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Blanket Orders';
                RunObject = Page "Blanket Purchase Orders";
                ToolTip = 'Create blanket purchase orders to mirror a contract.';
            }
        }
        addafter("Calc. and Pos&t VAT Settlement")
        {
            action("Close Income Statement")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Close Income Statement';
                Image = AnalysisView;
                RunObject = report 94;
                ToolTip = 'Close Income Statement';
            }
        }
        addafter("Purchase Blanket Order")
        {
            action("Purchase CR/Adj Notes")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase CR/Adj Notes';
                RunObject = Page 9309;
                ToolTip = 'Create Purchase Credit Notes so you can manage returns';
            }
        }
        addafter("Purchase CR/Adj Notes")
        {
            action("Purchase Return Order List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Return Orders';
                RunObject = Page 9311;
                ToolTip = 'Create Purchase Return Order so you can manage returns';
            }
        }
        addafter(Customers)
        {
            action("Sales Orders")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Orders';
                RunObject = Page "Sales Order List";
                ToolTip = 'Record your agreements with customers to sell certain products on certain delivery and payment terms. Sales orders, unlike sales invoices, allow you to ship partially, deliver directly from your vendor to your customer, initiate warehouse handling, and print various customer-facing documents. Sales invoicing is integrated in the sales order process.';
            }
        }
        addafter("Sales Orders")
        {
            action("Sales Invoices")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Invoices';
                RunObject = Page "Sales Invoice List";
                ToolTip = 'Register your sales to customers and invite them to pay according to the delivery and payment terms by sending them a sales invoice document. Posting a sales invoice registers shipment and records an open receivable entry on the customer''s account, which will be closed when payment is received. To manage the shipment process, use sales orders, in which sales invoicing is integrated.';
            }
        }
        addafter("Sales Invoices")
        {
            action("Sales Return Orders")
            {
                ApplicationArea = SalesReturnOrder;
                Caption = 'Sales Return Orders';
                RunObject = Page "Sales Return Order List";
                ToolTip = 'Compensate your customers for incorrect or damaged items that you sent to them and received payment for. Sales return orders enable you to receive items from multiple sales documents with one sales return, automatically create related sales credit memos or other return-related documents, such as a replacement sales order, and support warehouse documents for the item handling. Note: If an erroneous sale has not been paid yet, you can simply cancel the posted sales invoice to automatically revert the financial transaction.';
            }
        }
        addafter("Sales Return Orders")
        {
            action("Sales Credit Memos")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Credit Memos';
                RunObject = Page "Sales Credit Memos";
                ToolTip = 'Revert the financial transactions involved when your customers want to cancel a purchase or return incorrect or damaged items that you sent to them and received payment for. To include the correct information, you can create the sales credit memo from the related posted sales invoice or you can create a new sales credit memo with copied invoice information. If you need more control of the sales return process, such as warehouse documents for the physical handling, use sales return orders, in which sales credit memos are integrated. Note: If an erroneous sale has not been paid yet, you can simply cancel the posted sales invoice to automatically revert the financial transaction.';
            }
        }
        addafter("Chart of Accounts")
        {
            action(Items)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Items';
                Image = Item;
                RunObject = Page "Item List";
                ToolTip = 'View or edit detailed information for the products that you trade in. The item card can be of type Inventory or Service to specify if the item is a physical unit or a labor time unit. Here you also define if items in inventory or on incoming orders are automatically reserved for outbound documents and whether order tracking links are created between demand and supply to reflect planning actions.';
            }
        }
        addafter(PostedGeneralJournals)
        {
            action(ItemJournal)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Item Journal';
                Image = Item;
                RunObject = Page "Item Journal";
                ToolTip = 'Post item transactions directly to the item ledger to adjust inventory in connection with purchases, sales, and positive or negative adjustments without using documents. You can save sets of item journal lines as standard journals so that you can perform recurring postings quickly. A condensed version of the item journal function exists on item cards for quick adjustment of an items inventory quantity.';
            }
        }
        addafter(ItemJournal)
        {
            action(PhyInventoryJournal)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Physical Inventory Journal ';
                Image = Item;
                RunObject = Page "Phys. Inventory Journal";
                ToolTip = 'Prepare to count the actual items in inventory to check if the quantity registered in the system is the same as the physical quantity. If there are differences, post them to the item ledger with the physical inventory journal before you do the inventory valuation.';
            }
        }
        addafter(PhyInventoryJournal)
        {
            action(ReclassificationJournal)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Physical Inventory Journal ';
                Image = Item;
                RunObject = Page "Item Reclass. Journal";
                ToolTip = 'Change information recorded on item ledger entries. Typical inventory information to reclassify includes dimensions and sales campaign codes, but you can also perform basic inventory transfers by reclassifying location and bin codes. Serial or lot numbers and their expiration dates must be reclassified with the Item Tracking Reclassification journal.';
            }
        }
        addafter(ReclassificationJournal)
        {
            action(ReqWorksheet)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Requisition Worksheet';
                Image = Item;
                RunObject = Page "Req. Worksheet";
                ToolTip = 'Calculate a supply plan to fulfil item demand with purchases or transfers';
            }
        }
    }
}
