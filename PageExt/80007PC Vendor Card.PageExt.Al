pageextension 80007 "PC Vendor Card Ext" extends "Vendor Card"
{
    PromotedActionCategoriesML = ENU = 'New,Process,Report,Approve,Request Approval,New Document,Navigate,Incoming Documents,Vendor,Pet Culture',
                                 ENA = 'New,Process,Report,Approve,Request Approval,New Document,Navigate,Incoming Documents,Vendor,Pet Culture';

 
    layout
    {
        Modify("E-Mail")
        {
            ApplicationArea = All;
            Caption = 'Accounts E-Mail'; 
        }

        addafter("Balance Due (LCY)")
        {
            field("EDI Status";Rec."EDI Status")
            {
                ApplicationArea = All;
                Style = Strong;
            }
        }
        addafter("E-Mail")
        {
            field("Sales E-Mail"; rec."Sales E-Mail")
            {
                ApplicationArea = All;
                Importance = Additional;
                ExtendedDatatype = EMail;
            }
            field("Operations E-Mail"; rec."Operations E-Mail")
            {
                ApplicationArea = All;
                Importance = Additional;
                ExtendedDatatype = EMail;
            }
        }
    }
    actions
    {
        addafter("Ven&dor")
        {
            Group(PetCulture)
            {
                Action(MsgA)
                {
                    ApplicationArea = all;
                    Caption = 'PO Line Disc %';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category10;
                    ToolTip = 'PO Line Disc % Maintenance';
                    trigger OnAction()
                    var
                        Pg:Page "PC Supplier Brand Rebates";
                    begin
                        Pg.Set_Page_Mode(3,rec."No.");
                        Pg.RunModal();     
                    end;
                }
            }    
        }        
    }
}