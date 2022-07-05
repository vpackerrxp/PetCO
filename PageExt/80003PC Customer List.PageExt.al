pageextension 80003 "PC Customer List Ext" extends "Customer List"
{
   PromotedActionCategoriesML = ENU = 'New,Process,Report,Approve,New Document,Request Approval,Customer,Navigate,Prices & Discounts,Pet Culture',
                                ENA = 'New,Process,Report,Approve,New Document,Request Approval,Customer,Navigate,Prices & Discounts,Pet Culture';

    actions
    {
        addafter("Return Orders")
        {
            action("PCA")
            {
                ApplicationArea = All;
                Caption = 'Retrieve Shopify Orders';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category10;
                trigger OnAction()
                var
                    Cu: Codeunit "PC Shopify Routines";
               begin
                    If Confirm('Retrieve Orders From Shopify Now?',True) then
                        Cu.Get_Shopify_Orders(0);
                end;
            }
            action("PCB")
            {
                ApplicationArea = All;
                Caption = 'Shopify Orders';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category10;
                RunObject = Page "PC Shopify Orders";
            }
            action("PCC")
            {
                ApplicationArea = All;
                Caption = 'Process Shopify Orders';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category10;
                trigger OnAction()
                var 
                    Cu:Codeunit "PC Shopify Routines";
                begin
                    If Confirm('Process Shopify Orders Now?',True) then
                        Cu.Process_Orders(false,0);
                                       
                end;
            }
            action("PCD")
            {
                ApplicationArea = All;
                Caption = 'Shopify Discount Applications';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category10;
                RunObject = Page "PC Shopify Applications";
            }
            action("PCE")
            {
                ApplicationArea = All;
                Caption = 'Sales Processing';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category10;
                trigger OnAction()
                begin
                    Case StrMenu('Refunds,VetChat,Zero $,Auto Delivery,Analysis',1) of
                        1:PAGE.Run(PAGE::"PC Refund Processing");
                        2:PAGE.Run(PAGE::"PC Sales VetChat");
                        3:Page.Run(Page::"PC Zero Dollar Process");
                        4:Page.Run(Page::"PC Auto Delivery Processing");
                        5:PAGE.Run(PAGE::"PC Sales Analysis");
                    end;
                end;
            }
            action("PCF")
            {
                ApplicationArea = All;
                Caption = 'Shopify Daily Reconciliation';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category10;
                RunObject = Page "PC Shopify Order Recon";
            }
            action("PCF2")
            {
                ApplicationArea = All;
                Caption = 'Shopify Order Reconciliation';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category10;
                RunObject = Page "PC Order Reconciliation";
            }
            action("PCG")
            {
                ApplicationArea = All;
                Caption = 'Execution Log';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category10;
                RunObject = Page "PC Execution Log";
            }
        }    
    }
}