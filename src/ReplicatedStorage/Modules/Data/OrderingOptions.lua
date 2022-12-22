
local Module = {}

Module.MaxOrderForItem = 4
Module.MaxOrderTime = 20

Module.MenuSections = {
	'Entrees',
	'Mains',
	'Drinks',
	'Desserts'
}

-- https://www.taste.com.au/entertaining/galleries/48-easy-entrees/r9RVrYeu?page=43

Module.OrderingOptions = {

	GarlicBread = {
		MenuSection = 1,
		LayoutOrder = 1,

		Price = 0, -- change this later

		Display = {
			Title = { Text = "Garlic Bread", },
			UnderTitle = { Text = "4 pieces of delicious garlic delight.", },
		},
	},

	Bocconcini = {
		MenuSection = 1,
		LayoutOrder = 1,

		Price = 0, -- change this later

		Display = {
			Title = { Text = "Crispy Bocconcini", },
			UnderTitle = { Text = "with tomato chilli sauce.", },
		},
	},

	MixedOysters_HalfDozen = {
		MenuSection = 1,
		LayoutOrder = 1,

		Price = 0, -- change this later

		Display = {
			Title = { Text = "Mixed Oysters - 1/2 dozen.", },
			UnderTitle = { Text = "6 oysters, 3 rockefeller and 3 garlic.", },
		},
	},

	MixedOysters_Dozen = {
		MenuSection = 1,
		LayoutOrder = 1,

		Price = 0, -- change this later

		Display = {
			Title = { Text = "Mixed Oysters - full dozen.", },
			UnderTitle = { Text = "12 oysters, 6 rockefeller and 6 garlic.", },
		},
	},

	SpringRolls = {
		MenuSection = 1,
		LayoutOrder = 1,

		Price = 0, -- change this later

		Display = {
			Title = { Text = "Lumpia (spring rolls)", },
			UnderTitle = { Text = "half a dozen of spring rolls.", },
		},
	},

	SaucyMeatballs = {
		MenuSection = 1,
		LayoutOrder = 1,

		Price = 0, -- change this later

		Display = {
			Title = { Text = "Saucy Meatballs", },
			UnderTitle = { Text = "half a dozen of toothpick meatballs", },
		},
	},

	Asparagus = {
		MenuSection = 1,
		LayoutOrder = 1,

		Price = 0, -- change this later

		Display = {
			Title = { Text = "Barbecued asparagus", },
			UnderTitle = { Text = "6 bbqed asparaguses", },
		},
	},

}

return Module
