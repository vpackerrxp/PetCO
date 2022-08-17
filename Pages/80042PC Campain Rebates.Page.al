page 80042 "PC Campaign Rebates"
{
    ApplicationArea = All;
    Caption = 'Campaign Rebates';
    PageType = Worksheet;
    SourceTable = "PC Campaign Rebates";
    UsageCategory = Tasks;
    
    layout
    {
        area(content)
        {
            Group(Filters)
            {
                field("Rebate Vendor Filter";Supp)
                {
                    ApplicationArea = All;
                    TableRelation = Vendor."No." where("No."=filter('SKU*'));
                    trigger OnValidate()
                    Begin
                        Setfilters();
                    End;
                    trigger OnAssistEdit()
                    begin
                       Clear(Supp);
                       Setfilters();
                    end;
                }
                field("Campaign Filter";Camp)
                {
                   ApplicationArea = All;
                   TableRelation = "PC Campaign Rebates".Campaign;
                    trigger OnValidate()
                    Begin
                        Setfilters();
                    End;
                    trigger OnAssistEdit()
                    begin
                       Clear(Camp);
                       Setfilters();
                    end;
                }
            }
            Group(process)
            {
                Field("Export Template Type";TempType)
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                Field("A";'Export Campaign Data Template')
                {
                    ApplicationArea = All;
                    ShowCaption = False;
                    Style = Strong;
                    trigger OnDrillDown()
                    var
                        Cu:Codeunit "PC Import Export Routines";
                    begin
                        If Confirm(StrsubStno('Export Campaign Template as Type %1',TempType),True) then
                            Cu.Export_Campaign_Template(TempType);
                    end;    
                }
                Field("B";'Import Campaign Data')
                {
                    ApplicationArea = All;
                    ShowCaption = False;
                    Style = Strong;
                    trigger OnDrillDown()
                    var
                        Cu:Codeunit "PC Import Export Routines";
                    begin
                        Cu.Import_Campaign_Rebates();
                    end;    
                }
            }
            repeater(General)
            {
                field("Rebate Type"; Rec."Rebate Type")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Rebate Supplier No."; Rec."Rebate Supplier No.")
                {
                    ApplicationArea = All;
                }
                field(Campaign; Rec.Campaign)
                {
                    ApplicationArea = All;
                }
                field("Campaign Start Date"; Rec."Campaign Start Date")
                {
                    ApplicationArea = All;
                }
                field("Campaign End Date"; Rec."Campaign End Date")
                {
                    ApplicationArea = All;
                }
                field("Campaign SKUs";rec."Campaign SKUs")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    trigger OnClosePage()
    Var 
        CmpReb:Record "PC Campaign Rebates";
    begin
        //Clean up of Campaigns once they are done
        CmpReb.Reset;
        CmpReb.SetRange("Rebate Type",CmpReb."Rebate Type"::Campaign);
        CmpReb.Setfilter("Campaign End Date",'<=%1',Calcdate('-10D',Today));
        If CmpReb.findSet then CmpReb.DeleteAll(true);
    end;
    local procedure Setfilters();
    begin
        Rec.Reset();
        IF Supp <> '' then Rec.Setrange("Rebate Supplier No.",Supp);
        If Camp <> '' then Rec.Setrange(Campaign,Camp);
        CurrPage.update(false);
    end;
    var
        Supp:code[20];
        Camp:code[20];
        TempType:Option Campaign,"Auto Delivery";
}
