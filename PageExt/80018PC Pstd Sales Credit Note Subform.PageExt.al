pageextension 80018 "PC Pstd Sales Crd.Note Subfrm" extends "Posted Sales Cr. Memo Subform"
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
            field("Shopify Order Date";rec."Shopify Order Date")
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
            field("Palatabilty Status"; rec."Palatability Status")
            {
                ApplicationArea = All;
                Caption = 'Claim Status';
            }
        } 
   }
}    