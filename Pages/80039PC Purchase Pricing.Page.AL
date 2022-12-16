page 80039 "PC Purchase Pricing"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "PC Purchase Pricing";
    Caption = 'Purchase Pricing';
    
    PromotedActionCategoriesML = ENU = 'Pet Culture',
                                 ENA = 'Pet Culture';

    layout
    {
        area(Content)
        {
            Group(Filters)
            {
            field("Supplier Filter"; Supp)
                {
                    ApplicationArea = All;
                    Style = Strong;
                   trigger OnLookup(var Text: Text): Boolean
                    var
                        Vend:record Vendor;
                        Pg:Page "Vendor List";
                    begin
                        Clear(Supp);
                        Vend.reset;
                        Vend.Setfilter("No.",'SUP-*');
                        If Vend.Findset then
                        begin
                            Pg.SetTableView(Vend);
                            Pg.LookupMode := True;
                            If Pg.RunModal() = Action::LookupOK then
                            begin
                                Pg.GetRecord(Vend); 
                                Supp := Vend."No.";      
                           end;
                        end;
                        SetFilters();
                    end;    
                    trigger OnAssistEdit()
                    begin
                        Clear(Supp);
                        SetFilters();
                    end;
                }    
                field("SKU Filter";Sku)
                {
                    ApplicationArea = all;
                    Style = Strong;
                    TableRelation = Item where(type=Const(Inventory));
                    trigger OnValidate()
                    begin 
                        If not SkuLst.Contains(Sku) then
                            Skulst += SKU + '|';
                        Clear(sku);
                        SetFilters();   
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(SKU);
                        Clear(SkuLst);
                        SetFilters();   
                    end;
                }
                Field("Sku List";Skulst)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    MultiLine = true;
                    Editable = false;    
                }        

            }
            repeater(GroupName)
            {
                field("Item No.";rec."Item No.")
                {
                    ApplicationArea = All;
                }
                field(Description;rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Supplier Code";rec."Supplier Code")
                {
                    ApplicationArea = All;
                }
                field("Unit Cost";Rec."Unit Cost")
                {
                    ApplicationArea = All;
                }
                field("Start Date";rec."Start Date")
                {
                    ApplicationArea = All;
                  
                }
                field("End Date";rec."End Date")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    local procedure setfilters()
    Begin
        Rec.Reset();
        If Supp <> '' then Rec.Setrange("Supplier Code",Supp);
        If SkuLst <> '' then Rec.SetFilter("Item No.",Skulst.Remove(Skulst.LastIndexOf('|'),1));
        CurrPage.update(False);
    End;
    var
        Supp:Code[20];
        Sku:Code[20];
        SkuLst:text;
            
}