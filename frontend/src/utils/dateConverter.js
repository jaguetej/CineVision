const dateConvert = (date) => {
    return new Date(date).toLocaleDateString("es", {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });
}

export default dateConvert;