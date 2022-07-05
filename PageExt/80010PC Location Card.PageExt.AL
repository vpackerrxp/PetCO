pageextension 80010 "PC Location Card Ext" extends "Location Card"
{
    layout
    {
        addafter("Address & Contact")
        {

            Group("A")
            {
                caption = 'Pet Culture';
                field("Fulfilo Warehouse ID"; rec."Fulfilo Warehouse ID")
                {
                    ApplicationArea = All;
                }
                field("Fulfilo Warehouse Description"; rec."Fulfilo Warehouse Description")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}