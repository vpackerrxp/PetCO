pageextension 80014 "PC Purch. Rcpt. Subform Ext" extends "Posted Purchase Rcpt. Subform"
{
    layout
    {
        addafter("Location Code")
        {
            field("Line Rebate %"; rec."Line Rebate %")
            {
                ApplicationArea = All;
            }
        } 
        addafter(Quantity)
        {
            field("Fulfilo Recvd Qty";rec."Fulfilo Recvd Qty")
            {
               ApplicationArea = All;
            }
            field("Original Order Qty";rec."Original Order Qty")
            {
                ApplicationArea = All;
            }
            field("Original Order Qty(Base)";rec."Original Order Qty(Base)")
            {
                ApplicationArea = All;
            }
            field("Original Order UOM";rec."Original Order UOM")
            {
                ApplicationArea = All;
            }

        } 
   }
}  