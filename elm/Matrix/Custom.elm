module Matrix.Custom exposing (all, any, toListOfLists)

{-| Extra methods for Matricies

Imports for examples:

    import Char
    import Matrix exposing (empty, fromList)


# Assertions

@docs all, any


# Taking Matricies Apart

@docs toListOfLists

-}

import Array
import Matrix exposing (Matrix)


{-| Determine if all elements satisfy the predicate.

    Maybe.map (all Char.isUpper) (fromList [['A', 'B']])
    --> Just True

    Maybe.map (all Char.isUpper) (fromList [['a', 'B']])
    --> Just False

    all Char.isUpper empty
    --> True

-}
all : (a -> Bool) -> Matrix a -> Bool
all isOkay matrix =
    not (any (not << isOkay) matrix)


{-| Determine if any elements satisfy the predicate.

    Maybe.map (any Char.isUpper) (fromList [['a', 'B']])
    --> Just True

    Maybe.map (any Char.isUpper) (fromList [['a', 'b']])
    --> Just False

    any Char.isUpper empty
    --> False

-}
any : (a -> Bool) -> Matrix a -> Bool
any isOkay matrix =
    Array.length (Matrix.filter isOkay matrix) > 0


{-| Create a list of lists of elements from a matrix.

    Maybe.map toListOfLists (fromList [[3, 5, 8], [4, 6, 9]])
    --> Just [[3, 5, 8], [4, 6, 9]]

-}
toListOfLists : Matrix a -> List (List a)
toListOfLists matrix =
    List.range 0 (Matrix.height matrix - 1)
        |> List.filterMap (\y -> Matrix.getRow y matrix)
        |> List.map Array.toList
