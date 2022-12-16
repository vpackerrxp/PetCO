page 80036 "PC EDI Exceptions"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "PC EDI Exception Messages";
    InsertAllowed = false;
    ModifyAllowed = false;
    Caption = 'EDI Exceptions';
   
    PromotedActionCategoriesML = ENU = 'Pet Culture',
                                 ENA = 'Pet Culture';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Exception Date"; Rec."Exception Date")
                {
                    ApplicationArea = All;
                }
                field("Purchase Order No."; Rec."Purchase Order No.")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        PuchHdr:record "Purchase Header";
                        pg:Page "Purchase Order";
                    begin
                        If PuchHdr.Get(PuchHdr."Document Type"::Order,rec."Purchase Order No.") then
                        begin
                            Pg.SetRecord(PuchHdr);
                            Pg.RunModal();
                            CurrPage.update(false);
                       end;
                    end;
                }
                field(Messsage; Rec."Exception Message")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
            }
        }
    }
   actions
    {
        area(Processing)
        {
            action("Clear Exceptions")
            {
                ApplicationArea = All;
                
                trigger OnAction();
                var
                    Excp:Record "PC EDI Exception Messages";
                begin
                    If Confirm('Clear Displayed EDI Exceptions Now',True) then
                    begin
                        Excp.Reset;
                        Excp.Setrange("Purchase Order No.",Rec."Purchase Order No.");
                        if Excp.findset then  Excp.DeleteAll();    
                        CurrPage.Close();
                    end;    
                end;
            }
        }
    }
}