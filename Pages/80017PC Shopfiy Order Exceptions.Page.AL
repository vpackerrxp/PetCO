page 80017 "PC Shopify Order Exceptions"
{
    Caption = 'Order Exceptions';
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "PC Shopify Order Exceptions";
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    
    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Exception; rec.Exception)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
   
}