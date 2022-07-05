pageextension 80016 "PC Sales Crd. Note Subform Ext" extends "Sales Cr. memo subform"
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
             field("Palatabilty Reason"; rec."Palatability Reason")
            {
                ApplicationArea = All;
                Caption = 'Refund Reason';
            }
        } 
   }
}    