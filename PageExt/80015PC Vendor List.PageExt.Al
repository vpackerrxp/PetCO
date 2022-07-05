pageextension 80015 "PC Vendor List Ext" extends "Vendor List"
{
    PromotedActionCategoriesML = ENU ='New,Process,Report,New Document,Vendor,Navigate,Pet Culture',
                                 ENA = 'New,Process,Report,New Document,Vendor,Navigate,Pet Culture';
layout
    {
        
        addafter("Name")
        {
            field("EDI Status";Rec."EDI Status")
            {
                ApplicationArea = All;
                Style = Strong;
            }
        }
            
    }
    actions
    {
        addlast(processing)
        {
            Action(Msg1)
            {
                ApplicationArea = all;
                Caption = 'Vendor Rebates';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category7;
                ToolTip = 'Manages Vendor Rebates';
                RunObject = Page  "PC Rebate Payments";
            }
            Action(MsgA)
            {
                ApplicationArea = all;
                Caption = 'PO Line Disc %';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category7;
                ToolTip = 'PO Line Disc % Maintenance';
                trigger OnAction()
                var
                    Pg:Page "PC Supplier Brand Rebates";
                begin
                    Pg.Set_Page_Mode(3,'');
                    Pg.RunModal();     
                end;  
            }    
            Action(MsgB)
            {
                ApplicationArea = all;
                Caption = 'Cost Analysis';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category7;
                ToolTip = 'Product Cost Analysis';
                RunObject = PAGE "PC Cost Analysis";
            }    
            Action(Msgc)
            {
                ApplicationArea = all;
                Caption = 'Supplier Stock Qty';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category7;
                ToolTip = 'Displays Supplier Stock Quantities';
                trigger OnAction()
                var
                    Pg:Page "PC Vendor Stock";
                begin
                    Pg.RunModal();     
                end;
            }
            Action(MsgD)
            {
                ApplicationArea = all;
                Caption = 'Purchase Rebate History';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category7;
                ToolTip = 'Displays Purchase Rebate History';
                trigger OnAction()
                var
                    Pg:Page "PC Purchase Rebate History";
                begin
                    Pg.RunModal();     
                end;
            }
            Action(MsgE)
            {
                ApplicationArea = all;
                Caption = 'Simulate EDI Processing';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category7;
                trigger OnAction()
                var
                    CU:Codeunit "PC EDI Routines";
                begin
                    If Confirm('Simulate EDI Processing Now',True) then
                        Cu.Process_EDI_Transaction_Documents();
                end;
            }
        }    
    }
}