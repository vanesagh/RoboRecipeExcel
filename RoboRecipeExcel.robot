*** Settings ***
Documentation       Robot that calculates the price of a bread or a cake.

Library             RPA.Tables
Library             RPA.Excel.Files
Library             RPA.JSON
Library             ingredientsProcessing.py
Library             Collections
Library             Dialogs


*** Variables ***
${PRICES_WORKBOOK}      Precios Pasteles.xlsx
${INGREDIENTS_FILE}
...                     ..${/}RoboRecipes/Simple Panettone, Italian Christmas Bread Recipe_ingredients.json
${RECIPE_NAME}          Simple Panettone
@{COLUMNS}              item    quantity    units


*** Tasks ***
Create Budget Worksheet
    ${raw_materials_table}=    Get Raw Materials Worksheet As Table
    ${ingredients}=    Get Ingredients From JSON File    ${INGREDIENTS_FILE}
    ${recipe_ws}    ${workbook}=    Create Recipe Worksheet    ${RECIPE_NAME}
    Save Recipe Ingredients In Worksheet    ${ingredients}    ${recipe_ws}    ${workbook}
    Iterate Through The Whole Ingredients    ${raw_materials_table}    ${recipe_ws}    ${workbook}


*** Keywords ***
Get Raw Materials Worksheet As Table
    Open Workbook    ${PRICES_WORKBOOK}
    ${raw_materials_table}=    Read Worksheet As Table    Materia Prima    header=True
    Log    ${raw_materials_table}
    RETURN    ${raw_materials_table}

Get First Column of Raw Materials Table
    [Arguments]    ${raw_materials_table}
    ${products}=    Get Table Column    ${raw_materials_table}    Producto
    RETURN    ${products}

Ask User For The Most Similar Item
    [Arguments]    ${similar_items_list}    ${trans_item}
    ${similar_item}=    Get Selection From User    ${trans_item}    @{similar_items_list}    No encontrado. Pasar
    RETURN    ${similar_item}

Find Ingredients In Raw Materials Table
    [Arguments]    ${raw_materials_list}    ${trans_item}
    ${index_list}    ${similar_items_list}=    Compare Item With Raw Materials List
    ...    ${trans_item}
    ...    ${raw_materials_list}
    ${l}=    Get Length    ${index_list}
    RETURN    ${index_list}    ${similar_items_list}

Create Dictionary Of Similar Items
    [Arguments]    ${index_list}    ${similar_items_list}
    ${sim_items_dict}=    Create Dictionary
    FOR    ${index}    ${similar_item}    IN ZIP    ${index_list}    ${similar_items_list}
        Set To Dictionary    ${sim_items_dict}    ${similar_item}=${index}
    END
    RETURN    ${sim_items_dict}

Iterate Through The Whole Ingredients
    [Arguments]    ${raw_materials_table}    ${recipe_ws}    ${workbook}
    ${products}=    Get First Column of Raw Materials Table    ${raw_materials_table}
    ${ingredients_table}=    Read Worksheet As Table    ${RECIPE_NAME}    header=True

    FOR    ${index}    ${ingredient}    IN ENUMERATE    @{ingredients_table}
        IF    ${ingredient}[quantity]
            Log    ${ingredient}
            ${trans_item}=    Translate Item    ${ingredient}[item]
            ${index_list}    ${similar_items_list}=    Find Ingredients In Raw Materials Table
            ...    ${products}
            ...    ${trans_item}
            ${sim_items_dict}=    Create Dictionary Of Similar Items    ${index_list}    ${similar_items_list}
            ${similar_item}=    Ask User For The Most Similar Item    ${similar_items_list}    ${trans_item}
            IF    '${similar_item}' != 'No encontrado. Pasar'
                Log    ${index}
                Calculate Formula    ${similar_item}    ${sim_items_dict}    ${index}    ${recipe_ws}    ${workbook}
            END
        END
    END
