page 80012 "PC Supplier Brand List"
{
    Caption = 'Supplier Brands';
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "PC Supplier Brand Rebates";
    Editable = false;
    
    PromotedActionCategoriesML = ENU = 'Pet Culture',
                                 ENA = 'Pet Culture';

    layout
    {
     area(Content)
        {
             repeater(Group)
            {
                field(Brand; rec.Brand)
                {
                    ApplicationArea = All;
                }
           }
        }
    }
}    