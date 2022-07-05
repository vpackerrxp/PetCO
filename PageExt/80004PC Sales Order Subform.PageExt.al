pageextension 80004 "PC Sales Order Subform Ext" extends "Sales Order Subform"
{
    layout
    {
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