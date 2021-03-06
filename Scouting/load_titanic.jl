# Usage:
# include("load_titanic.jl")
# to return as arrays
# train, train_targets, test, test_targets = load()
# to return as JuliaDB tables
# train, train_targets, test, test_targets = load(true)

using JuliaDB

function convert_embarked(loc)
    if loc == "S"
        return 0
    elseif loc == "C"
        return 1
    else
        return 2
    end
end

# converts JuliaDB table to
# a regular array
function table_to_array(tab)
    arr = zeros(length(tab),length(tab[1]))
    for i = 1:length(tab[1])
        arr[:,i] = select(tab,i)
    end
    return arr
end

function load(as_table = false)
    # Load dataset
    titanic = loadtable("resources/titanic_train.csv")
    # remove any rows with NA values
    titanic_clean = dropna(titanic)

    # codify categorics
    titanic_clean = setcol(titanic_clean, :Sex, convert.(Int32, select(titanic_clean,:Sex) .== "male" ))
    titanic_clean = setcol(titanic_clean, :Embarked, convert_embarked.(select(titanic_clean,:Embarked)))

    # get rid of some columns
    titanic_clean = popcol(titanic_clean, :Ticket)
    titanic_clean = popcol(titanic_clean, :Cabin)
    titanic_clean =popcol(titanic_clean, :Name)

    # Divide into training-testing sets (fix seed)
    srand(1234)
    X = collect(1:length(titanic_clean))
    X = X[randperm(length(X))]
    test_indeces = X[1:80]
    train_indeces = X[81:end]

    # assemble the random samples
    test = titanic_clean[sort(test_indeces)]
    train = titanic_clean[sort(train_indeces)]

    train_targets = copy( select(train, :Survived) )
    train = popcol(train, :Survived)

    test_targets = copy( select(test, :Survived) )
    test = popcol(test, :Survived)

    if(as_table)
      return train, table(train_targets, names=[:Survived]), test, table(test_targets,names=[:Survived])
    else
      return table_to_array(train), train_targets, table_to_array(test), test_targets
    end
end

# generates some extra titanic data instances
# from random sampling of each column
# works on arrays
function expand_data(data,targets,n=500)
    # only binary classes
    x0 = find(targets.==0)
    x1 = find(targets.==1)

    new_X = zeros(2*n,size(data)[2])
    new_T = vcat(zeros(n),ones(n))
    for i in 1:size(data)[2]
        new_X[:,i] = vcat(rand(data[x0,i],n), rand(data[x1,i],n))
    end
    # so PassengersId is different
    new_X[:,1] = new_X[:,1]+1000;
    s = shuffle(1:size(new_X)[1]);
    new_X = new_X[s,:];
    new_T = new_T[s,:];
    
    return new_X,reshape(new_T,2*n)
end
