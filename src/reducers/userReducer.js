const defaultState = {
    user: {
        id: 0, // User id in Db
        firstname: "",
        lastname: "",
        username: "",
        pictureImg: "", // Maybe save the images to AWS or similar service?
    },
    projects: [],
};

export default (state = defaultState, action) => {
    switch (action.type) {
        case "LOGIN": {
            const newState = {
                user: action.user,
            };
            return newState;
        }
        case "UPDATE": {
            const newState = {
                user: action.newUsername,
            };
            return newState;
        } 
        default: 
            return state;
    }
};