pageextension 80017 "PC Pstd Sales Inv Subform Ext" extends "Posted Sales Invoice Subform"
{
    layout
    {
        addafter("No.")
        {
            field("Bundle Item No."; rec."Bundle Item No.")
            {
                ApplicationArea = All;
            }
            field("Bundle Order Qty"; rec."Bundle Order Qty")
            {
                ApplicationArea = All;
            }
            field("Bundle Unit Price"; rec."Bundle Unit Price")
            {
                ApplicationArea = All;
            }
        }
         
        addafter("Unit Price")
        {
            field("Shopify Ord ID"; rec."Shopify Order ID")
            {
                ApplicationArea = All;
            }
            field("Shopify Order No";rec."Shopify Order No")
            {
                ApplicationArea = All;
            }
             field("Shopify App ID"; rec."Shopify Application ID")
            {
                ApplicationArea = All;
            }
        } 
   }
}   