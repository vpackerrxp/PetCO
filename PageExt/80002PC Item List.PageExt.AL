pageextension 80002 "PC Item List Ext" extends "Item List"
{
    PromotedActionCategoriesML = ENU = 'New,Process,Report,Item,History,Special Prices & Discounts,Request Approval,Periodic Activities,Inventory,Attributes,Pet Culture',
                                 ENA = 'New,Process,Report,Item,History,Special Prices & Discounts,Request Approval,Periodic Activities,Inventory,Attributes,Pet Culture';
    layout
    {
        addafter(Type)
        {

            field("Shopify Item";rec."Shopify Item")
            {
                ApplicationArea = All;
            }
            field("Shopify Item Type";Check_Shopify_Type())
            {
                ApplicationArea = All;
                StyleExpr = Styler1;
            }
            field("Transfered To Shopify";Shopify_flag())
            {
                ApplicationArea = All;
                Caption = 'Transferred To Shopify';
                StyleExpr = Styler2;
            }
        }
    }
    actions
    {
        addafter(PricesandDiscounts)
        {
            Group("Pet Culture")
            {
                action(Msg1)
                {
                    ApplicationArea = all;
                    Caption = 'Synchronise All Shopify Items';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category11;
                    ToolTip = 'Updates All Shopify Items.';
                    trigger OnAction()
                    var
                        cu:Codeunit "PC Shopify Routines";
                    begin
                        If Confirm('Synchronise All Shopify Items Now?',True) then cu.Process_Shopify_Items('');
                    end;
                }
                action(Msg1A)
                {
                    ApplicationArea = all;
                    Caption = 'Synchronise Shopify Parent Items By Selection';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category11;
                    ToolTip = 'Updates Selected Parent Shopify Items.';
                    trigger OnAction()
                    var
                        cu:Codeunit "PC Shopify Routines";
                        Temp:Record Item temporary;
                   begin
                        If Confirm('Update All Marked Parent Items Into Shopify Now?',True) then
                        begin
                            CurrPage.SetSelectionFilter(rec);
                            temp.DeleteAll(False);
                            If rec.findSet then
                            repeat
                                temp.Copy(Rec);
                                Temp.insert(false);
                                Rec."Shopify Update Flag" := True;
                                Rec.Modify(false);    
                            until rec.Next = 0;
                            Temp.Reset;         
                            If Temp.Findset then
                            repeat
                                Cu.Process_Shopify_Items(Temp."No.");  
                            until temp.Next = 0;
                            rec.Reset;
                            CurrPage.update(false);
                        end;
                   end;
                } 
                action(Msg1B)
                {
                    ApplicationArea = all;
                    Caption = 'Synchronise Out Of Stock Shopify Items';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category11;
                    ToolTip = 'Sychronises Out Of Stock Items.';
                    trigger OnAction()
                    var
                        cu:Codeunit "PC Shopify Routines";
                    begin
                        If Confirm('Synchronise Out Of Stock Shopify Items Now?',True) then 
                            cu.Process_Out_Of_Stock_Shopify_Items();
                    end;
                }
                Action(Msg2)
                {
                    ApplicationArea = all;
                    Caption = 'Shopify Parent Item Management';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category11;
                    ToolTip = 'Manages Shopify Parents';
                    RunObject = Page "PC Shopify Parent List";
                }
                Action(Msg3)
                {
                    ApplicationArea = all;
                    Caption = 'Item Maintenance';
                    Image = Change;
                    Promoted = True;
                    PromotedCategory = Category11;
                    trigger OnAction()
                    var
                       Cu:Codeunit "PC Import Export Routines";
                    begin
                        Case StrMenu('Import/Export Shopify Items,Import/Export Parent/Child Shopify Items'
                                    + ',Import/Export Shopify BOM Items,Import/Export Item Changes,Import/Export MRP Items',1) of
                            1:CU.Build_Import_Export_Items();
                            2:Cu.Build_Import_Export_Item_Relations();
                            3:CU.Build_Import_Export_BOM();
                            4:CU.Build_Import_Export_Item_Changes();
                            5:CU.Build_MRP_Items();
                        end;
                    end;         
                } 
                Action(Msg4)
                {
                    ApplicationArea = all;
                    Caption = 'Shopify Item Management';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category11;
                    ToolTip = 'Manages Shopify Item Additions/Deletions';
                    RunObject = Page "PC Shopify Item Maintenance";
                } 
                Action(Msg4A)
                {
                    ApplicationArea = all;
                    Caption = 'Shopify Child Item Management';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category11;
                    ToolTip = 'Manages Shopify Child Item Additions/Deletions';
                    RunObject = Page "PC Shopify Child Maintenance";
                } 
                action(Msg5)
                {
                    ApplicationArea = All;
                    Caption = 'Shopify Price/Cost Management';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category11;
                    trigger OnAction()
                    var 
                        Pg:page "PC Shopify Pricing";
                        Pg1:page "PC Purchase Pricing";
                        Cu:Codeunit "PC Import Export Routines";
                    begin
                        Case StrMenu('Update Shopify Prices,Import/Export Shopify Prices,Update Shopify Costs,Import/Export Product Costs',1) of
                            1:
                                begin
                                    Pg.Set_item('');
                                    Pg.RunModal();
                                end;   
                            2:Cu.Build_Import_Export_Item_Prices();
                            3:Pg1.Runmodal;
                            4:Cu.Build_import_export_item_costs();
                       end;
                    end;         
                }
                action(Msg6)
                {
                    ApplicationArea = All;
                    Caption = 'Inventory Management';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category11;
                    RunObject = Page "PC Inventory Maintenance";
                }
                action(Msg7)
                {
                    ApplicationArea = All;
                    Caption = 'Check Shopify Items';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category11;
                    RunObject = Page "PC Check Shopify Items";
                }
                action(Msg8)
                {
                    ApplicationArea = All;
                    Caption = 'Setup';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category11;
                    RunObject = Page "Sales & Receivables Setup";
                }
                action(Msg9)
                {
                    ApplicationArea = All;
                    Caption = 'Shopify Update Log';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category11;
                    RunObject = Page "PC Shopify Update Log";
                }
            }
        }      
    }
    trigger OnAfterGetRecord()
    var
       ItemTxt:text;
    begin
        ItemTxt := Rec."No.";
        Styler1 := 'standard';
        Styler2 :=  'unfavorable';
        If rec."Is In Shopify Flag" then Styler2 := 'favorable';
        If (rec."Shopify Item" = rec."Shopify Item"::Shopify) AND rec."Is In Shopify Flag" then
        begin
            If (rec."Shopify Product ID" > 0) AND ItemTxt.StartsWith('PAR-') then
                Styler1 := 'strong'
            else If (rec."Shopify Product ID" > 0) AND ItemTxt.StartsWith('SKU-') then
                 Styler1 := 'favorable'
            else if (rec."Shopify Product Variant ID" > 0) then
                  Styler1 := 'strongaccent';
        end;
    end;
    local procedure Check_Shopify_Type():text
    var
        retval:text;
        ItemTxt:text;
    begin
       clear(retval);
       ItemTxt := Rec."No.";
       If (rec."Shopify Item" = rec."Shopify Item"::Shopify) And rec."Is In Shopify Flag" Then
        begin
            If (rec."Shopify Product ID" > 0) AND (rec."Shopify Product Variant ID" > 0) then
                If  ItemTxt.StartsWith('PAR-') then
                    retval := 'Parent'
                else
                    retval := 'Stand Alone'
            else if (rec."Shopify Product Variant ID" > 0) then
                retval := 'Child';
        end;
        Exit(retval);
    end;
    Local procedure Shopify_flag():Text
    begin
        If rec."Is In Shopify Flag" then
            exit('YES')
        else
            Exit('NO')    
    end;
    
    var
        Styler1:text;
        Styler2:text;
}